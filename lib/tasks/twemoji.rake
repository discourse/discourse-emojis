# frozen_string_literal: true

namespace :emojis do
  desc "Generate twemoji emoji set from remote zip file"
  task :twemoji do
    puts "Processing twemoji emoji set..."

    DiscourseEmojis::CodepointsEmojiProcessor.process(
      "twemoji",
      "https://github.com/jdecked/twemoji/archive/refs/tags/v16.0.1.zip",
      File.join("twemoji-16.0.1", "assets", "72x72"),
    )
  end
end
