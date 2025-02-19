# frozen_string_literal: true

require "fileutils"
require "json"

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
      "Light" => 1,
      "Medium-Light" => 2,
      "Medium" => 3,
      "Medium-Dark" => 4,
      "Dark" => 5,
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

      return unless emoji_name

      if supports_skin_tones?(emoji_dir)
        process_skin_tone_emoji(emoji_dir, emoji_name)
      else
        process_regular_emoji(emoji_dir, emoji_name)
      end
    end

    def load_metadata(emoji_dir)
      metadata_path = File.join(emoji_dir, "metadata.json")
      return unless File.exist?(metadata_path)

      JSON.parse(File.read(metadata_path))
    rescue JSON::ParserError
      nil
    end

    def valid_metadata?(metadata)
      return false if metadata.nil?
      return false unless metadata["glyph"]
      @supported_emojis[DiscourseEmojis::Utils.force_emoji_presentation(metadata["glyph"])]
    end

    def supports_skin_tones?(emoji_dir)
      Dir.exist?(File.join(emoji_dir, "Default")) &&
        SKIN_TONE_LEVELS.keys.all? { |tone| Dir.exist?(File.join(emoji_dir, tone)) }
    end

    def process_skin_tone_emoji(emoji_dir, emoji_name)
      default_svg = Dir.glob(File.join(emoji_dir, "Default", "Color", "*.svg")).first
      if File.exist?(default_svg)
        output_path = File.join(OUTPUT_DIR, "#{emoji_name}.png")
        FileUtils.mkdir_p(File.dirname(output_path))
        convert_svg_to_png(default_svg, output_path)
      end

      base_output_dir = File.join(OUTPUT_DIR, emoji_name)
      FileUtils.mkdir_p(base_output_dir)

      SKIN_TONE_LEVELS.each do |tone, level|
        svg_path = Dir.glob(File.join(emoji_dir, tone, "Color", "*.svg")).first
        next unless File.exist?(svg_path)

        output_path = File.join(base_output_dir, "#{level}.png")
        convert_svg_to_png(svg_path, output_path)
      end
    end

    def process_regular_emoji(emoji_dir, emoji_name)
      svg_path = Dir.glob(File.join(emoji_dir, "Color", "*.svg")).first
      return unless File.exist?(svg_path)

      output_path = File.join(OUTPUT_DIR, "#{emoji_name}.png")
      FileUtils.mkdir_p(File.dirname(output_path))
      convert_svg_to_png(svg_path, output_path)
    end

    def convert_svg_to_png(svg_path, output_png)
      FileUtils.mkdir_p(File.dirname(output_png))
      intermediate_png = "#{output_png}.tmp.png"
      step1_result =
        system(
          "rsvg-convert",
          "--background-color=none",
          "--width=288",
          "--height=288",
          "--output",
          intermediate_png,
          svg_path,
        )

      unless step1_result
        status = $?.nil? ? "unknown" : $?.exitstatus
        puts "Conversion step 1 failed with status: #{status}"
        return
      end

      step2_result = system("magick", intermediate_png, "-resize", "72x72", output_png)
      unless step2_result
        status = $?.nil? ? "unknown" : $?.exitstatus
        puts "Conversion step 2 (resize) failed with status: #{status}"
        return
      end

      FileUtils.rm_f(intermediate_png)
    end
  end
end
