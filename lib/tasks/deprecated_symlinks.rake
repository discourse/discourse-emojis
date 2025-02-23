# frozen_string_literal: true

namespace :emojis do
  desc "Symlinks deprecated emoji sets to the new ones"
  task :deprecated_symlinks do
    # All the sets are defined in core discourse at app/models/emoji_set_site_setting.rb
    DEPRECATED_SYMLINKS = {
      "apple" => "twemoji",
      "facebook_messenger" => "unicode",
      "google" => "noto",
      "google_classic" => "noto",
      "win10" => "fluentui",
      "emoji_one" => "twemoji",
      "twitter" => "twemoji",
    }

    FileUtils.cd(DiscourseEmojis.path_for_emojis) do
      DEPRECATED_SYMLINKS.each { |target, source| FileUtils.ln_s(source, target) }
    end
  end
end
