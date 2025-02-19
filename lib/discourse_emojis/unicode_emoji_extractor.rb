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
        next unless codepoint

        emoji_char = extract_emoji_char(row)
        next unless emoji_char

        image_data = extract_image_data(row)
        next unless image_data

        base_emojis[codepoint] = { char: emoji_char, image: image_data }
      end

      base_emojis
    end

    def parse_modifier_variations
      variations = []

      process_file(EMOJI_MODIFIER_FILE) do |row|
        full_codepoint = extract_codepoint(row)
        next unless full_codepoint&.include?("_")

        parts = full_codepoint.split("_")
        modifier = parts.find { |part| DiscourseEmojis::FITZPATRICK_SCALE.key?(part) }
        base = parts.reject { |part| part == modifier }.join("_")

        image_data = extract_image_data(row)
        next unless image_data

        variations << { base:, modifier:, image: image_data }
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
      return unless code_td

      link = code_td.at_xpath(".//a")
      link&.[]("name")
    end

    def extract_emoji_char(row)
      chars_td = row.xpath("./td[3]").first
      chars_td&.text&.strip
    end

    def extract_image_data(row)
      img_td = row.xpath("./td[4]").first
      return unless img_td

      img = img_td.at_xpath(".//img")
      return unless img

      src = img["src"]
      return unless src&.start_with?("data:image/png;base64,")

      Base64.decode64(src.split(",").last)
    end

    def save_emojis(base_emojis, variations)
      base_emojis.each do |codepoint, data|
        emoji_char = data[:char]
        emoji_name = @supported_emojis[DiscourseEmojis::Utils.force_emoji_presentation(emoji_char)]
        next unless emoji_name

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
