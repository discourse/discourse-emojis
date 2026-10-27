# frozen_string_literal: true

namespace :emojis do
  desc "Generate animated noto emoji set"
  task :noto_animated_emoji do
    puts "Processing animated noto emoji set..."

    DiscourseEmojis::NotoAnimatedEmojiProcessor.process
  end
end
