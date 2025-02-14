# frozen_string_literal: true

require_relative "constants"
require_relative "zip_processor"
require "fileutils"
require "tmpdir"
require "json"

module DiscourseEmojis
  class CodepointsEmojiProcessor
    EMOJI_TO_NAME_PATH = "./dist/emoji_to_name.json"

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
        process_image_files(asset_path, output_dir, supported_emojis)
      end

      def load_supported_emojis
        JSON.parse(File.read(EMOJI_TO_NAME_PATH))
      rescue JSON::ParserError, Errno::ENOENT => e
        raise "Failed to load emoji mapping: #{e.message}"
      end

      def process_image_files(asset_path, output_dir, supported_emojis)
        Dir
          .glob(File.join(asset_path, "*.png"))
          .each { |file| process_single_image(file, output_dir, supported_emojis) }
      end

      def process_single_image(file, output_dir, supported_emojis)
        filename = normalize_filename(file)

        codepoints = filename.split("_")

        fitzpatrick_level, base_codepoints = extract_fitzpatrick_scale(codepoints)
        emoji = convert_to_emoji(base_codepoints)
        emoji_name = supported_emojis[emoji]

        return unless emoji_name

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
        base_unicode = base_codepoints.map { |cp| cp.to_i(16) }

        # Add VS16 (0xFE0F) after the base character if needed
        # This is needed for emoji that can have both text and emoji presentation
        base_unicode.insert(1, 0xFE0F) if needs_variation_selector?(base_unicode.first)

        base_unicode.pack("U*") if base_unicode.all? { |cp| cp <= 0x10FFFF }
      end

      def needs_variation_selector?(codepoint)
        [
          (0x30..0x39).to_a, # Digits 0-9
          (0x23..0x23).to_a, # Hash (#)
          (0x2A..0x2A).to_a, # Asterisk (*)
          (0x2600..0x26FF).to_a, # Miscellaneous Symbols
          (0x2700..0x27BF).to_a, # Dingbats
        ].any? { |range| range.include?(codepoint) }
      end

      def save_emoji_image(source_file, output_dir, emoji_name, fitzpatrick_level)
        output_path = image_output_path(output_dir, emoji_name, fitzpatrick_level)
        FileUtils.mkdir_p(File.dirname(output_path))
        FileUtils.cp(source_file, output_path)
      end
    end
  end
end
