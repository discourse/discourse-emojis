# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "json"

module DiscourseEmojis
  class CodepointsEmojiProcessor
    # The CodepointsEmojiProcessor class is responsible for processing emoji images
    # based on their Unicode codepoints. It extracts emoji assets, maps them to
    # their respective names, and organizes them into the appropriate output
    # directory structure.
    #
    # Constants:
    # - EMOJI_TO_NAME_PATH: Path to the JSON file mapping emoji to names.
    # - TONABLE_EMOJIS_PATH: Path to the JSON file listing tonable emojis.
    #
    # Usage:
    # To process emoji images, call the `process` method with the necessary parameters:
    #
    # CodepointsEmojiProcessor.process(name, url, asset_subdir, output_dir)
    #
    # Parameters:
    # - name: The name of the emoji set being processed.
    # - url: The URL of the ZIP file containing the emoji assets.
    # - asset_subdir: The subdirectory within the extracted files where emoji images are located.
    # - output_dir: The directory where processed emoji images should be saved.
    #
    # Example:
    # CodepointsEmojiProcessor.process("twemoji", "https://example.com/twemoji.zip", "assets", "./output")

    EMOJI_TO_NAME_PATH = "./dist/emoji_to_name.json"
    TONABLE_EMOJIS_PATH = "./dist/tonable_emojis.json"

    class << self
      def process(name, url, asset_subdir, output_dir)
        ZipProcessor.with_extracted_files(url) do |extract_path|
          asset_path = File.join(extract_path, asset_subdir)
          process_images(asset_path, output_dir)
        end
      end

      private

      def image_output_path(output_dir, emoji_name, fitzpatrick_level)
        if fitzpatrick_level.nil?
          File.join(output_dir, "#{emoji_name}.png")
        else
          File.join(output_dir, emoji_name, "#{fitzpatrick_level}.png")
        end
      end

      def process_images(asset_path, output_dir)
        supported_emojis = load_supported_emojis
        tonable_emojis = load_tonable_emojis
        process_image_files(asset_path, output_dir, supported_emojis, tonable_emojis)
      end

      def load_supported_emojis
        JSON.parse(File.read(EMOJI_TO_NAME_PATH))
      rescue JSON::ParserError, Errno::ENOENT => e
        raise "Failed to load emoji mapping: #{e.message}"
      end

      def load_tonable_emojis
        JSON.parse(File.read(TONABLE_EMOJIS_PATH))
      rescue JSON::ParserError, Errno::ENOENT => e
        raise "Failed to load emoji mapping: #{e.message}"
      end

      def process_image_files(asset_path, output_dir, supported_emojis, tonable_emojis)
        Dir
          .glob(File.join(asset_path, "*.png"))
          .each { |file| process_single_image(file, output_dir, supported_emojis, tonable_emojis) }
      end

      def process_single_image(file, output_dir, supported_emojis, tonable_emojis)
        filename = normalize_filename(file)
        codepoints = filename.split("_")

        fitzpatrick_level, base_codepoints = extract_fitzpatrick_scale(codepoints)
        emoji = convert_to_emoji(base_codepoints)
        emoji_name = supported_emojis[emoji]

        return if !emoji_name
        return if fitzpatrick_level && !tonable_emojis.include?(emoji_name)

        save_emoji_image(file, output_dir, emoji_name, fitzpatrick_level)
      end

      def normalize_filename(file)
        File.basename(file, ".png").downcase.gsub("emoji_u", "").gsub("-", "_")
      end

      def extract_fitzpatrick_scale(codepoints)
        fitzpatrick_level = nil
        base_codepoints =
          codepoints.reject do |cp|
            if FITZPATRICK_SCALE.key?(cp)
              fitzpatrick_level = FITZPATRICK_SCALE[cp]
              true
            else
              false
            end
          end
        [fitzpatrick_level, base_codepoints]
      end

      def convert_to_emoji(base_codepoints)
        DiscourseEmojis::Utils.force_emoji_presentation(
          base_codepoints.map { |cp| cp.to_i(16) }.pack("U*"),
        )
      end

      def save_emoji_image(source_file, output_dir, emoji_name, fitzpatrick_level)
        output_path = image_output_path(output_dir, emoji_name, fitzpatrick_level)

        FileUtils.mkdir_p(File.dirname(output_path))
        FileUtils.cp(source_file, output_path)
      end
    end
  end
end
