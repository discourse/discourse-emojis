# frozen_string_literal: true

task :fluentui_emoji do
  url = "https://github.com/microsoft/fluentui-emoji/archive/refs/heads/main.zip"
  asset_subdir = File.join("fluentui-emoji-main", "assets")
  supported_emojis =
    JSON.parse(File.read(File.join(DiscourseEmojis.dist_path, "emoji_to_name.json")))

  DiscourseEmojis::ZipProcessor.with_extracted_files(url) do |extract_path|
    assets_dir = File.join(extract_path, asset_subdir)
    processor = DiscourseEmojis::FluentUIEmojiProcessor.new(assets_dir, supported_emojis)
    processor.process_all
  end
end
