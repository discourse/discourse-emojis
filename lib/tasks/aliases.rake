# frozen_string_literal: true

namespace :emojis do
  task "aliases" do
    puts "Generating aliases images..."

    DiscourseEmojis::EmojiAliasCreator.create_aliases
  end
end
