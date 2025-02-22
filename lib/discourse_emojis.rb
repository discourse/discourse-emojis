# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "json"
require "zip"
require "open-uri"

require_relative File.join(File.dirname(__FILE__), "discourse_emojis", "version")
require_relative "discourse_emojis/constants"
require_relative "discourse_emojis/zip_processor"
require_relative "discourse_emojis/emoji_synchronizer"
require_relative "discourse_emojis/unicode_emoji_extractor"
require_relative "discourse_emojis/codepoints_emoji_processor"
require_relative "discourse_emojis/fluentui_emoji_processor"
require_relative "discourse_emojis/emoji_alias_creator"
require_relative "discourse_emojis/utils"

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
      groups: File.join(dist_path, "groups.json"),
      emoji_to_name: File.join(dist_path, "emoji_to_name.json"),
    }
  end
end
