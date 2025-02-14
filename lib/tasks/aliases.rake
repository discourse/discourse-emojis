# frozen_string_literal: true

require "discourse_emojis"
require "./lib/discourse_emojis/emoji_alias_creator"
require "fileutils"

task "aliases" do
  DiscourseEmojis::EmojiAliasCreator.create_aliases
end
