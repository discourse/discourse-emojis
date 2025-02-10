# frozen_string_literal: true

desc "Copy missing emoji files from unicode directory to other emoji sets"
task :missing_emojis do
  require "fileutils"
  require_relative "../discourse_emojis/emoji_synchronizer"

  DiscourseEmojis::EmojiSynchronizer.sync_missing_emojis
end
