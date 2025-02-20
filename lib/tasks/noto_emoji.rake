# frozen_string_literal: true

namespace :emojis do
  desc "Generate noto emoji set from remote zip file"
  task :noto_emoji do
    DiscourseEmojis::CodepointsEmojiProcessor.process(
      "noto",
      "https://github.com/googlefonts/noto-emoji/archive/refs/tags/v2.047.zip",
      File.join("noto-emoji-2.047", "png", "72", "**"),
      File.expand_path("../../dist/emoji/noto", __dir__),
    )
  end
end
