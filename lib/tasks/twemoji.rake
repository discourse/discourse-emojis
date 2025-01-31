# frozen_string_literal: true

require 'discourse_emojis/emoji_processor'

task :twemoji do
  DiscourseEmojis::EmojiProcessor.process(
    "twemoji",
    "https://github.com/jdecked/twemoji/archive/refs/tags/v15.1.0.zip",
    File.join("twemoji-15.1.0", "assets", "72x72"),
    File.expand_path("../../db.json", __dir__),
    File.expand_path("../../vendor/emoji/twitter", __dir__)
  )
end
