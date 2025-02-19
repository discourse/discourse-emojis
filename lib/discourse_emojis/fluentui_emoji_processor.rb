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
      # Process default version
      default_svg = Dir.glob(File.join(emoji_dir, "Default", "Color", "*.svg")).first
      if File.exist?(default_svg)
        output_path = File.join(@output_dir, "#{emoji_name}.png")
        FileUtils.mkdir_p(File.dirname(output_path))
        convert_svg_to_png(default_svg, output_path)
      end

      # Process skin tone variations
      base_output_dir = File.join(@output_dir, emoji_name)
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

      output_path = File.join(@output_dir, "#{emoji_name}.png")
      FileUtils.mkdir_p(File.dirname(output_path))
      convert_svg_to_png(svg_path, output_path)
    end

    require "fileutils"

    def convert_svg_to_png(svg_path, output_png)
      FileUtils.mkdir_p(File.dirname(output_png))

      # Step 1: Convert SVG to a larger PNG (e.g., 288x288).
      # This uses rsvg-convert at a higher resolution.
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
        puts "Note: This requires librsvg2-bin to be installed."
        puts "Install with: brew install librsvg  # on macOS"
        puts "Or: sudo apt-get install librsvg2-bin  # on Ubuntu/Debian"
        return
      end

      # Step 2: Resize down to 72x72 using ImageMagick for smoother edges.
      step2_result = system("magick", intermediate_png, "-resize", "72x72", output_png)

      unless step2_result
        status = $?.nil? ? "unknown" : $?.exitstatus
        puts "Conversion step 2 (resize) failed with status: #{status}"
        puts "Note: This requires ImageMagick to be installed."
        puts "Install with: brew install imagemagick  # on macOS"
        puts "Or: sudo apt-get install imagemagick  # on Ubuntu/Debian"
        return
      end

      # Remove the temporary larger PNG
      FileUtils.rm_f(intermediate_png)
    end
  end
end
