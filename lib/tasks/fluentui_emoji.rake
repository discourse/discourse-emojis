# frozen_string_literal: true

require "discourse_emojis"

task :fluentui_emoji do
  url = File.join(DiscourseEmojis.root, "vendor/fluentui-emoji-main.zip")
  asset_subdir = File.join("fluentui-emoji-main", "assets")
  supported_emojis =
    JSON.parse(File.read(File.join(DiscourseEmojis.dist_path, "emoji_to_name.json")))

  DiscourseEmojis::ZipProcessor.with_extracted_files(url) do |extract_path|
    assets_dir = File.join(extract_path, asset_subdir)
    output_dir = File.join(DiscourseEmojis.emoji_dist_path, "fluentui")
    processor =
      DiscourseEmojis::FluentUIEmojiProcessor.new(assets_dir, supported_emojis, output_dir)
    processor.process_all
  end
end
