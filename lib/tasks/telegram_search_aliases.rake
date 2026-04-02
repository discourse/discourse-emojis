# frozen_string_literal: true

require "open-uri"
require "json"
require "fileutils"

def fetch_telegram_keywords(locale)
  url = "https://translations.telegram.org/#{locale}/emoji"
  html = URI.open(url).read

  match = html.match(/ajInit\((\{.+\})\)/)
  raise "Could not find ajInit data in Telegram page for locale '#{locale}'" unless match

  data = JSON.parse(match[1])
  data.dig("state", "initKeywords") ||
    raise("No initKeywords found in Telegram data for locale '#{locale}'")
end

def build_locale_search_aliases(keywords, emoji_to_name)
  aliases = {}

  keywords.each do |entry|
    keyword = entry["k"]&.strip&.downcase
    emoji_chars = entry["e"]&.strip
    next if keyword.nil? || keyword.empty? || emoji_chars.nil? || emoji_chars.empty?

    # Telegram separates multiple emojis with spaces, but emoji themselves can
    # contain spaces (e.g. ZWJ sequences with U+200D). Split on spaces that are
    # followed by an emoji-like codepoint to handle both cases.
    emojis = emoji_chars.scan(/\X+/).flat_map { |g| g.split(/\s+/) }.reject(&:empty?)

    emojis.each do |emoji_char|
      normalized = DiscourseEmojis::Utils.force_emoji_presentation(emoji_char)
      name = emoji_to_name[normalized]

      # Try without trailing FE0F if not found
      if name.nil?
        stripped = emoji_char.gsub("\u{FE0F}", "")
        normalized_stripped = DiscourseEmojis::Utils.force_emoji_presentation(stripped)
        name = emoji_to_name[normalized_stripped]
      end

      next if name.nil?

      # Skip keywords that are identical to the emoji name
      next if keyword.gsub(" ", "_") == name

      aliases[name] ||= []
      aliases[name] << keyword unless aliases[name].include?(keyword)
    end
  end

  aliases.sort.to_h
end

def available_telegram_locales
  html = URI.open("https://translations.telegram.org/en/emoji").read
  match = html.match(/ajInit\((\{.+\})\)/)
  return [] unless match

  data = JSON.parse(match[1])
  lang_names = data.dig("state", "langNames") || {}
  lang_names.keys.sort
end

namespace :emojis do
  namespace :telegram do
    desc "List available Telegram emoji locales"
    task :locales do
      puts "Fetching available locales..."
      locales = available_telegram_locales
      puts "#{locales.size} locales available:"
      locales.each { |l| puts "  #{l}" }
    end

    desc "Import Telegram emoji search aliases for given locales (comma-separated, or 'all')"
    task :import, [:locales] do |_t, args|
      min_emojis = 25
      locales_arg = args[:locales] || "en"

      emoji_to_name = JSON.parse(File.read("./dist/emoji_to_name.json"))
      output_dir = "./dist/locale_search_aliases"
      FileUtils.mkdir_p(output_dir)

      locales =
        if locales_arg == "all"
          puts "Fetching available locales..."
          available_telegram_locales
        else
          locales_arg.split(",").map(&:strip)
        end

      locales.each do |locale|
        print "Importing #{locale}... "

        begin
          keywords = fetch_telegram_keywords(locale)
          aliases = build_locale_search_aliases(keywords, emoji_to_name)

          if aliases.size < min_emojis
            puts "skipped (#{aliases.size} emojis, below minimum of #{min_emojis})"
            next
          end

          output_file = File.join(output_dir, "#{locale}.json")
          File.open(output_file, "w") { |f| f.write(JSON.pretty_generate(aliases)) }

          puts "done (#{aliases.size} emojis with aliases)"
        rescue => e
          puts "FAILED: #{e.message}"
        end
      end
    end
  end
end
