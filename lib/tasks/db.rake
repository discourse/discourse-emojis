# frozen_string_literal: true
require "nokogiri"
require "open-uri"
require "discourse_emojis/constants"

def generate_emoji_list(output_file)
  emoji_list =
    DiscourseEmojis::SUPPORTED_EMOJIS.map do |emoji, name|
      { "code" => emoji.codepoints.map { |cp| cp.to_s(16) }.join("-"), "name" => name }
    end

  File.open(output_file, "w") { |file| file.write(JSON.pretty_generate(emoji_list)) }

  puts "Saved to #{output_file}"
end

def generate_tonable_emoji_list(output_file)
  url = "https://unicode.org/Public/emoji/16.0/emoji-sequences.txt"

  # Download the file
  content = URI.open(url).read

  # Extract the last section: RGI_Emoji_Modifier_Sequence
  sections = content.split("# ================================================")
  last_section = sections.last

  # Extract lines with emoji sequences
  emoji_lines =
    last_section.each_line.select do |line|
      line.match?(/^[0-9A-F\s]+;\s*RGI_Emoji_Modifier_Sequence/)
    end

  # Extract base emoji (before the space separator in the sequence)
  emojis =
    emoji_lines.map do |line|
      hex_codes = line.split(";").first.strip.split
      base_emoji_hex = hex_codes.first # Get only the first part of the sequence
      [base_emoji_hex.to_i(16)].pack("U*") # Convert hex to Unicode character
    end

  File.open(output_file, "w") do |file|
    file.write(
      JSON.pretty_generate(
        emojis.uniq!.map { |emoji| DiscourseEmojis::SUPPORTED_EMOJIS[emoji] }.compact,
      ),
    )
  end

  puts "Saved to #{output_file}"
end

def generate_search_aliases(output_file)
  list = "https://raw.githubusercontent.com/unicode-org/cldr/main/common/annotations/en.xml"

  aliases = {}

  list = URI.open(list).read
  doc = Nokogiri.XML(list)
  doc
    .xpath("//annotation[not(@type='tts')]")
    .each do |node|
      emoji = node.attr("cp")
      next if emoji.nil? || emoji.strip.empty?

      name = DiscourseEmojis::SUPPORTED_EMOJIS[emoji]
      next if name.nil?

      aliases[name] ||= []
      aliases[name] << node.text.split("|").map(&:strip).reject { |a| a.gsub(" ", "_") == name }
      aliases[name].uniq!
    end

  File.open(output_file, "w") { |file| file.write(JSON.pretty_generate(aliases)) }

  puts "Saved to #{output_file}"
end

def generate_translations(output_file)
  File.open(output_file, "w") do |file|
    file.write(JSON.pretty_generate(DiscourseEmojis::TRANSLATIONS))
  end

  puts "Saved to #{output_file}"
end

def generate_aliases(output_file)
  File.open(output_file, "w") do |file|
    file.write(JSON.pretty_generate(DiscourseEmojis::EMOJI_ALIASES))
  end

  puts "Saved to #{output_file}"
end

def generate_groups(output_file)
  tonable_emojis =
    JSON.parse(File.read(File.expand_path("../../vendor/tonable_emojis.json", __dir__)))
  emoji_groups = Hash.new { |h, k| h[k] = [] }

  URI.open("https://unicode.org/Public/emoji/16.0/emoji-test.txt") do |file|
    current_group = nil

    file.each_line do |line|
      line.chomp!

      next if line.include?("skin tone")

      if line.start_with?("# group: ")
        current_group = line.sub("# group: ", "").strip
      elsif !line.start_with?("#") && !line.empty?
        before_comment, after_comment = line.split("#", 2)
        next unless after_comment

        emoji = after_comment.strip.split.first
        next unless emoji && current_group

        name = DiscourseEmojis::SUPPORTED_EMOJIS[emoji]
        next if name.nil?

        # Check if the base emoji is tonable using your list
        tonable = tonable_emojis.include?(name)
        emoji_groups[current_group] << { name:, tonable: tonable }
      end
    end
  end

  # Print the result in the desired format
  File.open(output_file, "w") { |file| file.write(JSON.pretty_generate(emoji_groups)) }

  puts "Saved to #{output_file}"
end

task :db do
  generate_emoji_list(File.expand_path("../../vendor/emojis.json", __dir__))
  generate_tonable_emoji_list(File.expand_path("../../vendor/tonable_emojis.json", __dir__))
  generate_search_aliases(File.expand_path("../../vendor/search_aliases.json", __dir__))
  generate_translations(File.expand_path("../../vendor/translations.json", __dir__))
  generate_groups(File.expand_path("../../vendor/groups.json", __dir__))
  generate_aliases(File.expand_path("../../vendor/aliases.json", __dir__))
end
