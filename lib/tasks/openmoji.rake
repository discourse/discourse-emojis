# frozen_string_literal: true

require 'discourse_emojis/emoji_processor'

task :openmoji do
  name = "openmoji"

  DiscourseEmojis::EmojiProcessor.process(
    name,
    "https://github.com/hfg-gmuend/openmoji/releases/latest/download/openmoji-72x72-color.zip",
    File.join("**"),
    File.expand_path('../../db.json', __dir__),
    File.expand_path("../../vendor/emoji/#{name}", __dir__)
  )
end
