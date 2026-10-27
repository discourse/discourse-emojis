# frozen_string_literal: true

require "net/http"

module DiscourseEmojis
  class NotoAnimatedEmojiProcessor < CodepointsEmojiProcessor
    METADATA_URL = "https://googlefonts.github.io/noto-emoji-animation/data/api.json"
    ASSET_URL = "https://fonts.gstatic.com/s/e/notoemoji/latest"

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
              batch.each do |icon|
                codepoint = icon.fetch("codepoint")
                next if !codepoint.match?(/\A[0-9a-f]+(?:_[0-9a-f]+)*\z/)

                tone, base_codepoints = extract_fitzpatrick_scale(codepoint.split("_"))
                name = supported_emojis[convert_to_emoji(base_codepoints)]
                next if !name || (tone && !tonable_emojis.include?(name))

                asset_codepoint = codepoint.split("_").map { |cp| cp.rjust(4, "0") }.join("_")
                image = download("#{ASSET_URL}/#{asset_codepoint}/512.webp")
                relative_path = tone ? File.join(name, "#{tone}.webp") : "#{name}.webp"
                target = File.join(output_dir, relative_path)
                FileUtils.mkdir_p(File.dirname(target))
                File.binwrite(target, image)
              end
            end
          end
          .each(&:value)
      end

      private

      def download(url)
        response = Net::HTTP.get_response(URI(url))
        raise "Failed to download #{url}: #{response.code}" if !response.is_a?(Net::HTTPSuccess)

        response.body
      end
    end
  end
end
