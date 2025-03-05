# frozen_string_literal: true

require "fileutils"
require "json"
require "selenium-webdriver"
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
      @driver = init_driver
    end

    def process_all
      Dir.glob(File.join(@assets_dir, "*")).each { |emoji_dir| process_emoji(emoji_dir) }
    ensure
      @driver.quit
    end

    private

    def init_driver
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless=new")
      options.add_argument("--disable-gpu")
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--force-device-scale-factor=2")
      driver = Selenium::WebDriver.for(:chrome, options: options)
      driver.execute_cdp(
        "Emulation.setDefaultBackgroundColorOverride",
        **{ "color" => { "r" => 0, "g" => 0, "b" => 0, "a" => 0 } },
      )
      driver
    end

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
        next if !File.exist?(svg_path)

        output_path = File.join(base_output_dir, "#{level}.png")
        convert_svg_to_png(svg_path, output_path)
      end
    end

    def process_regular_emoji(emoji_dir, emoji_name)
      svg_path = Dir.glob(File.join(emoji_dir, "Color", "*.svg")).first
      return if !File.exist?(svg_path)

      output_path = File.join(OUTPUT_DIR, "#{emoji_name}.png")
      FileUtils.mkdir_p(File.dirname(output_path))
      convert_svg_to_png(svg_path, output_path)
    end

    def convert_svg_to_png(svg_path, output_png)
      @driver.navigate.to(
        URI.join("file://", URI::DEFAULT_PARSER.escape(File.expand_path(svg_path)).to_s),
      )
      bbox = @driver.execute_script("return document.querySelector('svg').getBBox();")
      new_viewBox = "#{bbox["x"]} #{bbox["y"]} #{bbox["width"]} #{bbox["height"]}"

      @driver.execute_script(<<~JS, new_viewBox)
          const svg = document.querySelector('svg');
          svg.setAttribute('viewBox', arguments[0]);
          svg.removeAttribute('width');
          svg.removeAttribute('height');
          svg.style.width = "288px"
          svg.style.height = '288px';
          svg.style.background = 'transparent';
        JS

      svg_element = @driver.find_element(:css, "svg")
      png_data = svg_element.screenshot_as(:png)
      File.binwrite(output_png, png_data)

      resize_cmd = ["magick", output_png, "-resize", "72x72", output_png]
      unless system(*resize_cmd)
        puts "Error resizing image with ImageMagick."
        exit 1
      end
    end
  end
end
