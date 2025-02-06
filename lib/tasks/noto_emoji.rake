# frozen_string_literal: true

require "discourse_emojis/emoji_processor"

task :noto_emoji do
  name = "noto"

  DiscourseEmojis::EmojiProcessor.process(
    name,
    "https://github.com/googlefonts/noto-emoji/archive/refs/tags/v2.047.zip",
    File.join("noto-emoji-2.047", "png", "72", "**"),
    File.expand_path("../../dist/emoji/#{name}", __dir__),
  )
end
