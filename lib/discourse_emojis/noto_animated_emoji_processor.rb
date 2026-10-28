# frozen_string_literal: true

require "net/http"
require "open3"

module DiscourseEmojis
  class NotoAnimatedEmojiProcessor < CodepointsEmojiProcessor
    METADATA_URL = "https://googlefonts.github.io/noto-emoji-animation/data/api.json"
    ASSET_URL = "https://fonts.gstatic.com/s/e/notoemoji/latest"

    # Resize premultiplied pixels to avoid colored fringes along transparent edges.
    FILTER_GRAPH = [
      "[0:v]format=gbrapf32le,premultiply=inplace=1,scale=128:128:flags=lanczos," \
        "unpremultiply=inplace=1,format=rgba,split[c][a]",
      "[c]scale=out_color_matrix=bt601:out_range=full,format=yuv444p," \
        "setparams=colorspace=smpte170m:range=full[color]",
      "[a]alphaextract,setparams=colorspace=unknown:range=full[alpha]",
    ].join(";")

    class << self
      def process
        output_dir = File.join(DiscourseEmojis.path_for_emojis, "noto_animated")
        supported_emojis = load_supported_emojis
        tonable_emojis = load_tonable_emojis
        icons = JSON.parse(download(METADATA_URL)).fetch("icons")

        icons
          .each_slice([1, (icons.size / 4.0).ceil].max)
          .map do |batch|
            Thread.new do
              Dir.mktmpdir do |temp_dir|
                batch.each do |icon|
                  codepoint = icon.fetch("codepoint")
                  next if !codepoint.match?(/\A[0-9a-f]+(?:_[0-9a-f]+)*\z/)

                  tone, base_codepoints = extract_fitzpatrick_scale(codepoint.split("_"))
                  name = supported_emojis[convert_to_emoji(base_codepoints)]
                  next if !name || (tone && !tonable_emojis.include?(name))

                  asset_codepoint = codepoint.split("_").map { |cp| cp.rjust(4, "0") }.join("_")
                  image = download("#{ASSET_URL}/#{asset_codepoint}/512.webp")
                  relative_path = tone ? File.join(name, "#{tone}.avif") : "#{name}.avif"
                  target = File.join(output_dir, relative_path)
                  FileUtils.mkdir_p(File.dirname(target))
                  source = File.join(temp_dir, "source.webp")
                  File.binwrite(source, image)
                  encoded = File.join(temp_dir, "encoded.avif")
                  convert_animation(source, encoded)
                  FileUtils.mv(encoded, target)
                end
              end
            end
          end
          .each(&:value)
      end

      private

      def convert_animation(source, target)
        _, error, status =
          Open3.capture3(
            "ffmpeg",
            "-v",
            "error",
            "-nostdin",
            "-y",
            "-i",
            source,
            "-filter_complex_threads",
            "1",
            "-filter_complex",
            FILTER_GRAPH,
            "-map",
            "[color]",
            "-map",
            "[alpha]",
            "-c:v",
            "libaom-av1",
            "-cpu-used",
            "2",
            "-threads",
            "1",
            "-crf:v:0",
            "31",
            "-crf:v:1",
            "32",
            "-b:v",
            "0",
            "-tune:v:0",
            "ssim",
            "-tune:v:1",
            "psnr",
            "-lag-in-frames",
            "0",
            "-color_primaries:v:0",
            "bt709",
            "-color_trc:v:0",
            "iec61966-2-1",
            "-fps_mode",
            "passthrough",
            "-enc_time_base",
            "1:1000",
            "-loop",
            "0",
            target,
          )
        if !status.success?
          raise "Failed to encode Noto animation (requires FFmpeg 9+ with libaom): #{error}"
        end
      end

      def download(url)
        response = Net::HTTP.get_response(URI(url))
        raise "Failed to download #{url}: #{response.code}" if !response.is_a?(Net::HTTPSuccess)

        response.body
      end
    end
  end
end
