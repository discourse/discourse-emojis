# frozen_string_literal: true

namespace :emojis do
  desc "Generate openmoji emoji set from remote zip file"
  task :openmoji do
    puts "Processing openmoji emoji set..."
    DiscourseEmojis::CodepointsEmojiProcessor.process(
      "openmoji",
      "https://github.com/hfg-gmuend/openmoji/releases/download/16.0.0/openmoji-72x72-color.zip",
      File.join("**"),
    )
  end
end
