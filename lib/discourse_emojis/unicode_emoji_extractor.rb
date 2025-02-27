# frozen_string_literal: true

require "nokogiri"
require "base64"
require "fileutils"
require_relative "constants"

module DiscourseEmojis
  # The UnicodeEmojiExtractor processes HTML files containing emoji data from the Unicode consortium.
  # It extracts emoji images and their skin tones variations from base64-encoded images in
  # the HTML files and saves them to the appropriate directories in the project's emoji system.
  #
  # The extractor handles two types of files:
  # 1. emoji-list.html - Contains base emoji images
  # 2. emoji-modifier-sequences.html - Contains emoji variations (e.g., skin tones)

  class UnicodeEmojiExtractor
    UNICODE_EMOJI_DIR = "dist/emoji/unicode"
    EMOJI_LIST_FILE = "vendor/emoji-list.html"
    EMOJI_MODIFIER_FILE = "vendor/emoji-modifier-sequences.html"

    def initialize(supported_emojis_path: "./dist/emoji_to_name.json")
      @supported_emojis = JSON.parse(File.read(supported_emojis_path))
    end

    def extract_and_save
      FileUtils.mkdir_p(UNICODE_EMOJI_DIR)

      base_emojis = parse_base_emojis
      variations = parse_modifier_variations

      save_emojis(base_emojis, variations)
    end

    private

    def parse_base_emojis
      base_emojis = {}

      process_file(EMOJI_LIST_FILE) do |row|
        codepoint = extract_codepoint(row)

        next if !codepoint

        char = extract_emoji_char(row)
        next if !char

        image = extract_image_data(row)
        next if image

        base_emojis[codepoint] = { char:, image: }
      end

      base_emojis
    end

    def parse_modifier_variations
      variations = []

      needs_fe0f_base_code =
        Set.new(
          File
            .readlines("./vendor/emoji-variation-sequences.txt")
            .grep(/FE0F\s*;\s*emoji style;/)
            .map { |line| line[/^([0-9A-F]+)/, 1].downcase },
        )

      process_file(EMOJI_MODIFIER_FILE) do |row|
        full_codepoint = extract_codepoint(row)
        next unless full_codepoint&.include?("_")

        # If the emoji is compound (i.e. includes a ZWJ, represented as "200d")
        if full_codepoint.include?("200d")
          segments = full_codepoint.split("_200d_")
          processed_segments =
            segments.map do |segment|
              parts = segment.split("_")
              # Find any Fitzpatrick modifier in this segment
              segment_modifier = parts.find { |part| DiscourseEmojis::FITZPATRICK_SCALE.key?(part) }
              if parts.length > 2 && needs_fe0f_base_code.include?(parts.first)
                if segment_modifier
                  # Already has a Fitzpatrick modifier – preserve the segment as is.
                  segment
                else
                  # No skin tone is present but this base needs FE0F,
                  # so ensure that "fe0f" appears immediately after the base.
                  parts.insert(1, "fe0f") unless parts[1] == "fe0f"
                  parts.join("_")
                end
              else
                # For segments that are not “tonable” (or that don’t need fe0f),
                # remove any Fitzpatrick modifier that might be present.
                parts.reject { |part| DiscourseEmojis::FITZPATRICK_SCALE.key?(part) }.join("_")
              end
            end
          base = processed_segments.join("_200d_")
          # For compound sequences, pick the first Fitzpatrick modifier found (if any)
          modifier =
            segments
              .map { |seg| seg.split("_").find { |p| DiscourseEmojis::FITZPATRICK_SCALE.key?(p) } }
              .compact
              .first
        else
          # Non compound sequences
          parts = full_codepoint.split("_")
          modifier = parts.find { |part| DiscourseEmojis::FITZPATRICK_SCALE.key?(part) }
          if parts.length > 2 && needs_fe0f_base_code.include?(parts.first)
            if modifier
              # Replace the modifier with "fe0f" if present
              base = parts.map { |part| part == modifier ? "fe0f" : part }.join("_")
            else
              base = parts.join("_")
            end
          else
            base = parts.reject { |part| part == modifier }.join("_")
          end
        end

        image = extract_image_data(row)
        next if !image

        variations << { base:, modifier:, image: }
      end

      variations
    end

    def process_file(pattern)
      Dir
        .glob("./#{pattern}")
        .each do |file|
          doc = File.open(file) { |f| Nokogiri.HTML(f) }
          doc.xpath("//tr").each { |row| yield(row) }
        end
    end

    def extract_codepoint(row)
      code_td = row.xpath("./td[2]").first
      return if !code_td

      link = code_td.at_xpath(".//a")
      link&.[]("name")
    end

    def extract_emoji_char(row)
      chars_td = row.xpath("./td[3]").first
      chars_td&.text&.strip
    end

    def extract_image_data(row)
      img_td = row.xpath("./td[4]").first
      return if !img_td

      img = img_td.at_xpath(".//img")
      return if !img

      src = img["src"]
      return if !src&.start_with?("data:image/png;base64,")

      Base64.decode64(src.split(",").last)
    end

    def save_emojis(base_emojis, variations)
      base_emojis.each do |codepoint, data|
        emoji_char = data[:char]
        emoji_name = @supported_emojis[DiscourseEmojis::Utils.force_emoji_presentation(emoji_char)]
        next if !emoji_name

        save_base_emoji(emoji_name, data[:image])
        save_variations(emoji_name, codepoint, variations)
      end
    end

    def save_base_emoji(emoji_name, image_data)
      File.open("#{UNICODE_EMOJI_DIR}/#{emoji_name}.png", "wb") { |f| f.write(image_data) }
    end

    def save_variations(emoji_name, codepoint, variations)
      emoji_variations = variations.select { |v| v[:base] == codepoint }
      return if emoji_variations.empty?

      variation_dir = "#{UNICODE_EMOJI_DIR}/#{emoji_name}"
      FileUtils.mkdir_p(variation_dir)

      emoji_variations.each do |var|
        level = FITZPATRICK_SCALE[var[:modifier]]
        filename = "#{variation_dir}/#{level}.png"
        File.open(filename, "wb") { |f| f.write(var[:image]) }
      end
    end
  end
end
