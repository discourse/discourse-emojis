# frozen_string_literal: true

namespace :emojis do
  desc "Extract emoji images from Unicode HTML files and save them to the unicode directory"
  task :unicode do
    puts "Processing unicode emoji set..."

    DiscourseEmojis::UnicodeEmojiProcessor.new.extract_and_save
  end
end
