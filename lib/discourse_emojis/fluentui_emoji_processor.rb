# frozen_string_literal: true

module DiscourseEmojis
  class FluentUIEmojiProcessor
    SKIN_TONE_LEVELS = {
      "Light" => 1,
      "Medium-Light" => 2,
      "Medium" => 3,
      "Medium-Dark" => 4,
      "Dark" => 5,
    }

    def initialize(assets_dir, supported_emojis, output_dir = "dist/emoji/fluentui")
      @assets_dir = assets_dir
      @supported_emojis = supported_emojis
      @output_dir = output_dir
    end

    def process_all
      Dir.glob(File.join(@assets_dir, "*")).each { |emoji_dir| process_emoji(emoji_dir) }
    end

    private

    def process_emoji(emoji_dir)
      metadata = load_metadata(emoji_dir)
      return unless valid_metadata?(metadata)

      emoji_name = @supported_emojis[metadata["glyph"]]

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

      @supported_emojis.key?(metadata["glyph"])
    end

    def supports_skin_tones?(emoji_dir)
      Dir.exist?(File.join(emoji_dir, "Default")) &&
        SKIN_TONE_LEVELS.keys.all? { |tone| Dir.exist?(File.join(emoji_dir, tone)) }
    end

    def process_skin_tone_emoji(emoji_dir, emoji_name)
      # Process default version
      default_svg = File.join(emoji_dir, "Default", "Color", "#{emoji_name}.svg")
      if File.exist?(default_svg)
        output_path = File.join(@output_dir, "#{emoji_name}.png")
        FileUtils.mkdir_p(File.dirname(output_path))
        convert_svg_to_png(default_svg, output_path)
      end

      # Process skin tone variations
      base_output_dir = File.join(@output_dir, emoji_name)
      FileUtils.mkdir_p(base_output_dir)

      SKIN_TONE_LEVELS.each do |tone, level|
        tone_name = tone.downcase
        svg_name = "#{emoji_name}_color_#{tone_name}.svg"
        svg_path = File.join(emoji_dir, tone, "Color", svg_name)

        next unless File.exist?(svg_path)
        output_path = File.join(base_output_dir, "#{level}.png")
        convert_svg_to_png(svg_path, output_path)
      end
    end

    def process_regular_emoji(emoji_dir, emoji_name)
      # Try both with and without _color suffix
      svg_path = File.join(emoji_dir, "Color", "#{emoji_name}.svg")
      svg_path = File.join(emoji_dir, "Color", "#{emoji_name}_color.svg") unless File.exist?(
        svg_path,
      )
      return unless File.exist?(svg_path)

      output_path = File.join(@output_dir, "#{emoji_name}.png")
      FileUtils.mkdir_p(File.dirname(output_path))
      convert_svg_to_png(svg_path, output_path)
    end

    def convert_svg_to_png(svg_path, output_png)
      FileUtils.mkdir_p(File.dirname(output_png))

      result =
        system(
          "rsvg-convert",
          "-w",
          "72",
          "-h",
          "72",
          "--keep-aspect-ratio",
          "--dpi-x",
          "300",
          "--dpi-y",
          "300",
          "-o",
          output_png,
          svg_path,
        )

      unless result
        status = $?.nil? ? "unknown" : $?.exitstatus
        puts "Conversion failed with status: #{status}"
        puts "Note: This requires librsvg2-bin to be installed."
        puts "Install with: brew install librsvg  # on macOS"
        puts "Or: sudo apt-get install librsvg2-bin  # on Ubuntu/Debian"
      end
    end
  end
end
