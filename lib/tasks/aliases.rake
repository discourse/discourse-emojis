# frozen_string_literal: true

namespace :emojis do
  task "aliases" do
    DiscourseEmojis::EmojiAliasCreator.create_aliases
  end
end
