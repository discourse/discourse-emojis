# frozen_string_literal: true

namespace :emojis do
  desc "Generate noto 3D emoji set"
  task :noto_3d_emoji do
    puts "Processing noto 3D emoji set..."

    DiscourseEmojis::Noto3DEmojiProcessor.process
  end
end
