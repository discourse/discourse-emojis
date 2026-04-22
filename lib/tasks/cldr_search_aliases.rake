# frozen_string_literal: true

require "net/http"
require "json"
require "rexml/document"
require "fileutils"

CLDR_BASE_URL = "https://raw.githubusercontent.com/unicode-org/cldr/latest/common"

# Maps Discourse locale codes to an ordered list of CLDR source files to union.
#
# CLDR uses locale inheritance: child files (e.g. pt_PT, en_GB, zh_Hant) contain
# only overrides/deltas over the base file. To get full keyword coverage for a
# Discourse locale that corresponds to a child CLDR locale, we must union the
# base file and the child overrides.
#
# Portuguese caveat called out by upstream: in modern CLDR, pt.xml is Brazilian
# Portuguese (the root), and pt_PT.xml contains European Portuguese overrides.
#   - Discourse pt_BR ← CLDR [pt]
#   - Discourse pt    ← CLDR [pt, pt_PT]
DISCOURSE_TO_CLDR_LOCALES = {
  "ar" => ["ar"],
  "be" => ["be"],
  "bg" => ["bg"],
  "bs_BA" => ["bs"],
  "ca" => ["ca"],
  "cs" => ["cs"],
  "da" => ["da"],
  "de" => ["de"],
  "el" => ["el"],
  "en" => ["en"],
  "en_GB" => %w[en en_GB],
  "es" => ["es"],
  "et" => ["et"],
  "fa_IR" => ["fa"],
  "fi" => ["fi"],
  "fr" => ["fr"],
  "gl" => ["gl"],
  "he" => ["he"],
  "hr" => ["hr"],
  "hu" => ["hu"],
  "hy" => ["hy"],
  "id" => ["id"],
  "it" => ["it"],
  "ja" => ["ja"],
  "ko" => ["ko"],
  "lt" => ["lt"],
  "lv" => ["lv"],
  "nb_NO" => ["nb"],
  "nl" => ["nl"],
  "pl_PL" => ["pl"],
  "pt" => %w[pt pt_PT],
  "pt_BR" => ["pt"],
  "ro" => ["ro"],
  "ru" => ["ru"],
  "sk" => ["sk"],
  "sl" => ["sl"],
  "sq" => ["sq"],
  "sr" => ["sr"],
  "sv" => ["sv"],
  "sw" => ["sw"],
  "te" => ["te"],
  "th" => ["th"],
  "tr_TR" => ["tr"],
  "uk" => ["uk"],
  "ur" => ["ur"],
  "vi" => ["vi"],
  "zh_CN" => ["zh"],
  "zh_TW" => %w[zh zh_Hant],
}.freeze

def fetch_cldr_xml(cldr_locale, subdir)
  url = URI("#{CLDR_BASE_URL}/#{subdir}/#{cldr_locale}.xml")
  response = Net::HTTP.get_response(url)
  return nil if response.is_a?(Net::HTTPNotFound)
  raise "HTTP #{response.code} fetching #{url}" unless response.is_a?(Net::HTTPSuccess)
  response.body.force_encoding("UTF-8")
end

def parse_cldr_annotations(xml_string)
  doc = REXML::Document.new(xml_string)
  result = {}
  doc.each_element("//annotation") do |el|
    # Skip TTS variants — they're single descriptive phrases meant for
    # accessibility, not searchable keyword sets.
    next if el.attributes["type"] == "tts"

    emoji = el.attributes["cp"]
    next if emoji.nil? || emoji.empty?

    keywords = el.text.to_s.split("|").map(&:strip).reject(&:empty?)
    result[emoji] ||= []
    result[emoji].concat(keywords)
  end
  result
end

def collect_cldr_keywords(cldr_locales)
  combined = {}
  cldr_locales.each do |locale|
    %w[annotations annotationsDerived].each do |subdir|
      xml =
        begin
          fetch_cldr_xml(locale, subdir)
        rescue => e
          warn "  warning: failed fetching #{subdir}/#{locale}.xml: #{e.message}"
          nil
        end
      next unless xml

      parse_cldr_annotations(xml).each do |emoji, keywords|
        combined[emoji] ||= []
        combined[emoji].concat(keywords)
      end
    end
  end
  combined
end

def build_aliases_from_cldr(cldr_keywords, emoji_to_name)
  aliases = {}

  cldr_keywords.each do |emoji_char, keywords|
    normalized = DiscourseEmojis::Utils.force_emoji_presentation(emoji_char)
    name = emoji_to_name[normalized]

    if name.nil?
      stripped = emoji_char.gsub("\u{FE0F}", "")
      normalized_stripped = DiscourseEmojis::Utils.force_emoji_presentation(stripped)
      name = emoji_to_name[normalized_stripped]
    end

    next if name.nil?

    keywords.each do |raw_keyword|
      keyword = raw_keyword.strip.downcase
      next if keyword.empty?
      next if keyword.gsub(" ", "_") == name

      aliases[name] ||= []
      aliases[name] << keyword if !aliases[name].include?(keyword)
    end
  end

  aliases.sort.to_h
end

namespace :emojis do
  namespace :cldr do
    desc "List Discourse locales mapped to CLDR sources"
    task :locales do
      DISCOURSE_TO_CLDR_LOCALES.sort.each do |discourse, cldr_list|
        puts "  #{discourse} <- CLDR #{cldr_list.join(" + ")}"
      end
    end

    desc "Import CLDR emoji search aliases for given locales (comma-separated, or 'all')"
    task :import, [:locales] do |_t, args|
      min_emojis = 25
      locales_arg = args[:locales] || "en"

      emoji_to_name = JSON.parse(File.read("./dist/emoji_to_name.json"))
      output_dir = "./dist/cldr_search_aliases"
      FileUtils.mkdir_p(output_dir)

      targets =
        if locales_arg == "all"
          DISCOURSE_TO_CLDR_LOCALES.keys
        else
          locales_arg.split(",").map(&:strip)
        end

      targets.each do |discourse_locale|
        cldr_list = DISCOURSE_TO_CLDR_LOCALES[discourse_locale]

        unless cldr_list
          puts "Skipping #{discourse_locale} (no CLDR mapping)"
          next
        end

        print "Importing #{discourse_locale} <- CLDR #{cldr_list.join("+")}... "

        begin
          cldr_keywords = collect_cldr_keywords(cldr_list)
          aliases = build_aliases_from_cldr(cldr_keywords, emoji_to_name)

          if aliases.size < min_emojis
            puts "skipped (#{aliases.size} emojis, below minimum of #{min_emojis})"
            next
          end

          output_file = File.join(output_dir, "#{discourse_locale}.json")
          File.open(output_file, "w") { |f| f.write(JSON.pretty_generate(aliases)) }

          puts "done (#{aliases.size} emojis with aliases)"
        rescue => e
          puts "FAILED: #{e.message}"
        end
      end
    end
  end
end
