# frozen_string_literal: true

require "fileutils"
require "json"
require "uri"

module DiscourseEmojis
  class FluentUIEmojiProcessor
    # The FluentUIEmojiProcessor class processes Fluent UI emoji assets and converts
    # them into PNG format for use in the application. It supports both regular and
    # skin-tone variations of emojis.
    #
    # Constants:
    # - SKIN_TONE_LEVELS: A mapping of skin tone names to numerical levels used for file naming.
    # - OUTPUT_DIR: The directory where processed PNG files will be saved.
    #
    # Usage:
    # To process all Fluent UI emojis from an assets directory, instantiate the class
    # and call the `process_all` method:
    #
    # processor = DiscourseEmojis::FluentUIEmojiProcessor.new(assets_dir, supported_emojis)
    # processor.process_all
    #
    # Parameters:
    # - assets_dir: The directory containing Fluent UI emoji assets.
    # - supported_emojis: A mapping of supported emoji names.
    #
    # This method will iterate over each emoji asset, check if it has skin-tone variations,
    # and convert the SVG files into properly formatted PNG images.

    SKIN_TONE_LEVELS = {
      "Light" => 2,
      "Medium-Light" => 3,
      "Medium" => 4,
      "Medium-Dark" => 5,
      "Dark" => 6,
    }

    OUTPUT_DIR = "dist/emoji/fluentui"

    def initialize(assets_dir, supported_emojis)
      @assets_dir = assets_dir
      @supported_emojis = supported_emojis
    end

    def process_all
      Dir.glob(File.join(@assets_dir, "*")).each { |emoji_dir| process_emoji(emoji_dir) }
    end

    private

    def process_emoji(emoji_dir)
      metadata = load_metadata(emoji_dir)
      emoji_name = valid_metadata?(metadata)

      return if !emoji_name

      if supports_skin_tones?(emoji_dir)
        process_skin_tone_emoji(emoji_dir, emoji_name)
      else
        process_regular_emoji(emoji_dir, emoji_name)
      end
    end

    def load_metadata(emoji_dir)
      metadata_path = File.join(emoji_dir, "metadata.json")
      return if !File.exist?(metadata_path)

      JSON.parse(File.read(metadata_path))
    rescue JSON::ParserError
      nil
    end

    def valid_metadata?(metadata)
      return false if metadata.nil?
      return false if !metadata["glyph"]
      @supported_emojis[DiscourseEmojis::Utils.force_emoji_presentation(metadata["glyph"])]
    end

    def supports_skin_tones?(emoji_dir)
      Dir.exist?(File.join(emoji_dir, "Default")) &&
        SKIN_TONE_LEVELS.keys.all? { |tone| Dir.exist?(File.join(emoji_dir, tone)) }
    end

    def process_skin_tone_emoji(emoji_dir, emoji_name)
      default_png = Dir.glob(File.join(emoji_dir, "Default", "3D", "*.png")).first
      if File.exist?(default_png)
        output_path = File.join(OUTPUT_DIR, "#{emoji_name}.png")
        FileUtils.mkdir_p(File.dirname(output_path))
        resize_png(default_png, output_path)
      end

      base_output_dir = File.join(OUTPUT_DIR, emoji_name)
      FileUtils.mkdir_p(base_output_dir)

      SKIN_TONE_LEVELS.each do |tone, level|
        png_path = Dir.glob(File.join(emoji_dir, tone, "3D", "*.png")).first
        next if !File.exist?(png_path)

        output_path = File.join(base_output_dir, "#{level}.png")
        resize_png(png_path, output_path)
      end
    end

    def process_regular_emoji(emoji_dir, emoji_name)
      png_path = Dir.glob(File.join(emoji_dir, "3D", "*.png")).first
      return if !File.exist?(png_path)

      output_path = File.join(OUTPUT_DIR, "#{emoji_name}.png")
      FileUtils.mkdir_p(File.dirname(output_path))
      resize_png(png_path, output_path)
    end

    def resize_png(png_path, output_png)
      resize_cmd = [
        "magick",
        png_path,
        "-trim",
        "-resize",
        "72x72",
        "-gravity",
        "center",
        "-background",
        "transparent",
        "-extent",
        "72x72",
        output_png,
      ]
      unless system(*resize_cmd)
        puts "Error resizing image with ImageMagick."
        exit 1
      end
    end
  end
end
