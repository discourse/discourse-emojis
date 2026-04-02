# frozen_string_literal: true

require_relative File.join(File.dirname(__FILE__), "discourse_emojis", "version")
require_relative "discourse_emojis/railtie" if defined?(Rails)

module DiscourseEmojis
  def self.root
    File.expand_path("../..", __FILE__)
  end

  def self.path_for_emojis
    File.join(dist_path, "emoji")
  end

  def self.dist_path
    File.join(root, "dist")
  end

  def self.paths
    {
      emojis: File.join(dist_path, "emojis.json"),
      translations: File.join(dist_path, "translations.json"),
      tonable_emojis: File.join(dist_path, "tonable_emojis.json"),
      aliases: File.join(dist_path, "aliases.json"),
      search_aliases: File.join(dist_path, "search_aliases.json"),
      locale_search_aliases: File.join(dist_path, "locale_search_aliases"),
      groups: File.join(dist_path, "groups.json"),
      emoji_to_name: File.join(dist_path, "emoji_to_name.json"),
    }
  end
end
