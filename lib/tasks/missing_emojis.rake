# frozen_string_literal: true

desc "Copy missing emoji files from unicode directory to other emoji sets"
task :missing_emojis do
  DiscourseEmojis::EmojiSynchronizer.sync_missing_emojis
end
