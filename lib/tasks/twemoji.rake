# frozen_string_literal: true

namespace :emojis do
  desc "Generate twemoji emoji set from remote zip file"
  task :twemoji do
    DiscourseEmojis::CodepointsEmojiProcessor.process(
      "twemoji",
      "https://github.com/jdecked/twemoji/archive/refs/tags/v15.1.0.zip",
      File.join("twemoji-15.1.0", "assets", "72x72"),
      File.expand_path("../../dist/emoji/twemoji", __dir__),
    )
  end
end
