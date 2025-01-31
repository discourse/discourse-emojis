# frozen_string_literal: true

module DiscourseEmojis
  class Railtie < Rails::Railtie
    initializer "discourse_emojis.configure_application" do |app|
      emojis_path = File.join(app.config.root, "public/images/emoji")
      if !File.exist?(emojis_path) || File.realpath(emojis_path) != DiscourseEmojis.path_for_emojis
        STDERR.puts "Symlinking emojis from discourse-emojis gem"
        File.delete(emojis_path) if File.exist?(emojis_path)
        Discourse::Utils.atomic_ln_s(DiscourseEmojis.path_for_emojis, emojis_path)
      end

      Discourse::Utils.atomic_ln_s(
        File.expand_path("../../../vendor/groups.json", __FILE__),
        File.join(app.config.root, "lib/emoji/groups.json"),
      )
    end
  end
end
