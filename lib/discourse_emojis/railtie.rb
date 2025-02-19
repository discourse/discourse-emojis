# frozen_string_literal: true

module DiscourseEmojis
  class Railtie < ::Rails::Railtie
    initializer "discourse_emojis.configure_application" do |app|
      emoji_dir = File.join(app.config.root, "public/images/emoji")

      if !Dir.exist?(emoji_dir) || File.realpath(emoji_dir) != DiscourseEmojis.path_for_emojis
        FileUtils.rm_rf(emoji_dir) if Dir.exist?(emoji_dir)
        Discourse::Utils.atomic_ln_s(DiscourseEmojis.path_for_emojis, emoji_dir)

        DEPRECATED_SYMLINKS = {
          "apple" => "unicode",
          "facebook_messenger" => "unicode",
          "google" => "noto",
          "google_classic" => "noto",
          "win10" => "dist/emoji/fluentui",
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
end
