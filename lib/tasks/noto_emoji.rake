# frozen_string_literal: true

namespace :emojis do
  desc "Generate noto emoji set from remote zip file"
  task :noto_emoji do
    puts "Processing noto emoji set..."

    DiscourseEmojis::CodepointsEmojiProcessor.process(
      "noto",
      "https://github.com/googlefonts/noto-emoji/archive/refs/tags/v2.051.zip",
      File.join("noto-emoji-2.051", "png", "72", "**"),
    )
  end
end
