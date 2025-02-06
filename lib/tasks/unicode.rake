# frozen_string_literal: true

task :unicode do
  require "nokogiri"
  require "base64"
  require "fileutils"

  require_relative "../discourse_emojis/constants"

  def parse_base_emojis
    base_emojis = {}

    Dir
      .glob("./vendor/emoji-list.html")
      .each do |html_file|
        doc = File.open(html_file) { |f| Nokogiri.HTML(f) }

        doc
          .xpath("//tr")
          .each do |row|
            # Extract codepoint
            code_td = row.xpath("./td[2]").first
            next unless code_td
            link = code_td.at_xpath(".//a")
            next unless link
            codepoint = link["name"]
            next unless codepoint

            # Extract emoji character
            chars_td = row.xpath("./td[3]").first
            next unless chars_td
            emoji_char = chars_td.text.strip

            # Extract base image
            img_td = row.xpath("./td[4]").first
            next unless img_td
            img = img_td.at_xpath(".//img")
            next unless img
            src = img["src"]
            next unless src.start_with?("data:image/png;base64,")

            base_emojis[codepoint] = {
              char: emoji_char,
              image: Base64.decode64(src.split(",").last),
            }
          end
      end
    base_emojis
  end

  def parse_modifier_variations
    variations = []

    Dir
      .glob("./vendor/emoji-modifier-sequences.html")
      .each do |html_file|
        doc = File.open(html_file) { |f| Nokogiri.HTML(f) }

        doc
          .xpath("//tr")
          .each do |row|
            # Extract full codepoint
            code_td = row.xpath("./td[2]").first
            next unless code_td
            link = code_td.at_xpath(".//a")
            next unless link
            full_codepoint = link["name"]
            next if !full_codepoint.include?("_")

            # Split into base and modifier
            base_part, modifier_part = full_codepoint.downcase.split("_", 2)
            next unless DiscourseEmojis::FITZPATRICK_SCALE.key?(modifier_part)

            # Extract variation image
            img_td = row.xpath("./td[4]").first
            next unless img_td
            img = img_td.at_xpath(".//img")
            next unless img
            src = img["src"]
            next unless src.start_with?("data:image/png;base64,")

            variations << {
              base: base_part,
              modifier: modifier_part,
              image: Base64.decode64(src.split(",").last),
            }
          end
      end
    variations
  end

  # Create the dist/emoji/unicode directory if it doesn't exist
  FileUtils.mkdir_p("dist/emoji/unicode")

  # Process emojis
  base_emojis = parse_base_emojis
  variations = parse_modifier_variations
  supported_emojis = JSON.parse(File.read("./dist/emoji_to_name.json"))

  base_emojis.each do |codepoint, data|
    emoji_char = data[:char]
    emoji_name = supported_emojis[emoji_char]
    next unless emoji_name

    # Save base emoji (level 1) to dist/emoji/unicode
    File.open("dist/emoji/unicode/#{emoji_name}.png", "wb") { |f| f.write(data[:image]) } # Changed path
    puts "Saved base: dist/emoji/unicode/#{emoji_name}.png" # Updated output message

    # Find related variations
    emoji_variations = variations.select { |v| v[:base] == codepoint }
    next if emoji_variations.empty?

    # Create directory for variations inside dist/emoji/unicode
    variation_dir = "dist/emoji/unicode/#{emoji_name}" # New path
    FileUtils.mkdir_p(variation_dir) # Updated directory path

    # Save variations
    emoji_variations.each do |var|
      level = DiscourseEmojis::FITZPATRICK_SCALE[var[:modifier]]
      filename = "#{variation_dir}/#{level}.png" # Updated path
      File.open(filename, "wb") { |f| f.write(var[:image]) }
      puts "Saved variation: #{filename}"
    end
  end
end
