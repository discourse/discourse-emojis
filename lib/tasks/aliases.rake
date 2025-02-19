# frozen_string_literal: true

task "aliases" do
  DiscourseEmojis::EmojiAliasCreator.create_aliases
end
