# frozen_string_literal: true

namespace :emojis do
  desc "Copy missing emoji files from unicode directory to other emoji sets"
  task :missing_emojis do
    puts "Copying missing emojis from unicode..."

    DiscourseEmojis::EmojiSynchronizer.sync_missing_emojis
  end
end
