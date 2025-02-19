# frozen_string_literal: true
require "nokogiri"
require "open-uri"
require "discourse_emojis/constants"
require "discourse_emojis/utils"
require "i18n"

def generate_emoji_lists(emoji_to_name_file, emojis_file)
  I18n.available_locales = [:en]

  mapping = {}
  emojis = []

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

          # Extract name
          name_td = row.xpath("./td[9]").first
          next unless name_td
          name = name_td.text.strip

          # Extract emoji character
          chars_td = row.xpath("./td[3]").first
          next unless chars_td

          emoji_char = DiscourseEmojis::Utils.force_emoji_presentation(chars_td.text.strip)

          name =
            name
              .downcase
              .gsub("’", "_")
              .gsub("!", "")
              .gsub(": ", "_")
              .gsub(" ", "_")
              .gsub("-", "_")
              .gsub("(", "")
              .gsub(")", "")
              .gsub(",_", "_")
              .gsub("___", "_")
              .gsub(".", "")
              .gsub("”", "")
              .gsub("“", "")
              .gsub("⊛_", "")
              .gsub("flag_", "")
              .gsub("_&_", "_")

          mapping[emoji_char] = I18n.transliterate(name)

          emojis << { name:, code: codepoint.gsub("_", "-") }
        end
    end

  File.open(emoji_to_name_file, "w") { |file| file.write(JSON.pretty_generate(mapping)) }
  puts "Saved to#{emoji_to_name_file}"

  File.open(emojis_file, "w") { |file| file.write(JSON.pretty_generate(emojis)) }
  puts "Saved to #{emojis_file}"
end

def generate_tonable_emoji_list(output_file)
  supported_emojis = JSON.parse(File.read("./dist/emoji_to_name.json"))
  fitzpatrick_emojis = []

  supported_emojis.each do |emoji, name|
    fitzpatrick_emojis << name if DiscourseEmojis::Utils.can_be_toned?(emoji)
  end

  File.open(output_file, "w") { |file| file.write(JSON.pretty_generate(fitzpatrick_emojis.uniq)) }
  puts "Saved to #{output_file}"
end

def generate_search_aliases(output_file)
  aliases = {}
  supported_emojis = JSON.parse(File.read("./dist/emoji_to_name.json"))

  list = File.read("./vendor/cldr-annotations.xml")
  doc = Nokogiri.XML(list)
  doc
    .xpath("//annotation[not(@type='tts')]")
    .each do |node|
      emoji = node.attr("cp")
      next if emoji.nil? || emoji.strip.empty?

      name = supported_emojis[emoji]
      next if name.nil?

      aliases[name] ||= []
      aliases[name] << node.text.split("|").map(&:strip).reject { |a| a.gsub(" ", "_") == name }
      aliases[name].flatten!.uniq!
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
  supported_emojis = JSON.parse(File.read("./dist/emoji_to_name.json"))
  tonable_emojis = JSON.parse(File.read("./dist/tonable_emojis.json"))
  emoji_groups = []

  file = File.open("./vendor/emoji-test.txt")

  current_group = nil

  file.each_line do |line|
    line.chomp!

    next if line.include?("skin tone")

    if line.start_with?("# group: ")
      if current_group && current_group[:icons].any?
        current_group[:tabicon] = DiscourseEmojis::EMOJI_GROUPS[current_group[:name]]
        emoji_groups << current_group
      end

      current_group = { name: line.sub("# group: ", "").strip.downcase.gsub(/ /, "_"), icons: [] }
    elsif !line.start_with?("#") && !line.empty?
      before_comment, after_comment = line.split("#", 2)
      next unless after_comment

      emoji = after_comment.strip.split.first
      next unless emoji && current_group

      name = supported_emojis[emoji]
      next if name.nil?

      # Check if the base emoji is tonable using your list
      tonable = tonable_emojis.include?(name)
      current_group[:icons] << { name:, tonable: tonable }
    end
  end

  # Print the result in the desired format
  File.open(output_file, "w") { |f| f.write(JSON.pretty_generate(emoji_groups)) }

  puts "Saved to #{output_file}"
end

task :db do
  generate_emoji_lists("./dist/emoji_to_name.json", "./dist/emojis.json")
  generate_tonable_emoji_list("./dist/tonable_emojis.json")
  generate_search_aliases("./dist/search_aliases.json")
  generate_translations("./dist/translations.json")
  generate_groups("./dist/groups.json")
  generate_aliases("./dist/aliases.json")
end
