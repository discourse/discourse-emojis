# frozen_string_literal: true

desc "Extract emoji images from Unicode HTML files and save them to the unicode directory"
task :unicode do
  DiscourseEmojis::UnicodeEmojiExtractor.new.extract_and_save
end
