# frozen_string_literal: true

namespace :emojis do
  desc "Generate openmoji emoji set from remote zip file"
  task :openmoji do
    DiscourseEmojis::CodepointsEmojiProcessor.process(
      "openmoji",
      "https://github.com/hfg-gmuend/openmoji/releases/download/15.1.0/openmoji-72x72-color.zip",
      File.join("**"),
      File.expand_path("../../dist/emoji/openmoji", __dir__),
    )
  end
end
