# frozen_string_literal: true

module DiscourseEmojis
  class Railtie < ::Rails::Railtie
    initializer "discourse_emojis.configure_application" do |app|
      emoji_dir = File.join(app.config.root, "public/images/emoji")

      FileUtils.rm_rf(emoji_dir)

      Discourse::Utils.atomic_ln_s(DiscourseEmojis.path_for_emojis, emoji_dir)

      # All the sets are defined in core discourse at app/models/emoji_set_site_setting.rb
      DEPRECATED_SYMLINKS = {
        "apple" => "unicode",
        "facebook_messenger" => "unicode",
        "google" => "noto",
        "google_classic" => "noto",
        "win10" => "fluentui",
      }

      DEPRECATED_SYMLINKS.each do |target, source|
        Discourse::Utils.atomic_ln_s(
          File.join(DiscourseEmojis.path_for_emojis, source),
          File.join(emoji_dir, target),
        )
      end

      STDERR.puts "\nCreated emoji symlink: #{DiscourseEmojis.path_for_emojis} -> #{emoji_dir}\n\n"
    end
  end
end
