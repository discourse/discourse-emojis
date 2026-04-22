# frozen_string_literal: true

require "json"
require "fileutils"

SEARCH_ALIAS_SOURCES = %w[telegram cldr].freeze

def load_source_aliases(source, discourse_locale)
  path = "./dist/#{source}_search_aliases/#{discourse_locale}.json"
  return {} unless File.exist?(path)
  JSON.parse(File.read(path))
end

def merge_alias_sources(discourse_locale)
  merged = {}

  SEARCH_ALIAS_SOURCES.each do |source|
    load_source_aliases(source, discourse_locale).each do |emoji_name, keywords|
      merged[emoji_name] ||= []
      keywords.each { |kw| merged[emoji_name] << kw if !merged[emoji_name].include?(kw) }
    end
  end

  merged.sort.to_h
end

def discover_alias_locales
  locales = []
  SEARCH_ALIAS_SOURCES.each do |source|
    dir = "./dist/#{source}_search_aliases"
    next unless Dir.exist?(dir)
    locales.concat(
      Dir.children(dir).select { |f| f.end_with?(".json") }.map { |f| f.sub(/\.json\z/, "") },
    )
  end
  locales.uniq.sort
end

namespace :emojis do
  namespace :search_aliases do
    desc "Merge per-source search alias files (Telegram, CLDR) into dist/locale_search_aliases/"
    task :merge do
      output_dir = "./dist/locale_search_aliases"
      FileUtils.mkdir_p(output_dir)

      locales = discover_alias_locales

      if locales.empty?
        puts "No source alias files found under dist/{telegram,cldr}_search_aliases/"
        next
      end

      locales.each do |discourse_locale|
        merged = merge_alias_sources(discourse_locale)
        next if merged.empty?

        output_file = File.join(output_dir, "#{discourse_locale}.json")
        File.open(output_file, "w") { |f| f.write(JSON.pretty_generate(merged)) }

        sources_present =
          SEARCH_ALIAS_SOURCES.select do |s|
            File.exist?("./dist/#{s}_search_aliases/#{discourse_locale}.json")
          end
        puts "  #{discourse_locale}: #{merged.size} emojis (#{sources_present.join(" + ")})"
      end
    end
  end
end
