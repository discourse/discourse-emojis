# frozen_string_literal: true

require "discourse_emojis/codepoints_emoji_processor"

task :openmoji do
  name = "openmoji"

  DiscourseEmojis::CodepointsEmojiProcessor.process(
    name,
    "https://github.com/hfg-gmuend/openmoji/releases/download/15.1.0/openmoji-72x72-color.zip",
    File.join("**"),
    File.expand_path("../../dist/emoji/#{name}", __dir__),
  )
end
