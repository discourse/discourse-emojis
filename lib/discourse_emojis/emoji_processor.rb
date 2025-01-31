# frozen_string_literal: true

require_relative "constants"
require "open-uri"
require "zip"
require "fileutils"
require "tmpdir"
require "json"

module DiscourseEmojis
  class EmojiProcessor
    def self.process(name, url, asset_subdir, output_dir)
      zip_path = File.join(Dir.tmpdir, "#{name}.zip")
      extract_path = Dir.mktmpdir

      begin
        download_zip(url, zip_path)
        extract_zip(zip_path, extract_path)
        asset_path = File.join(extract_path, asset_subdir)
        process_images(asset_path, output_dir)
      ensure
        FileUtils.remove_entry(extract_path)
        FileUtils.remove_entry(zip_path)
      end
    end

    def self.download_zip(url, zip_path)
      URI.open(url) { |download| File.open(zip_path, "wb") { |file| file.write(download.read) } }
    end

    def self.extract_zip(zip_path, extract_path)
      Zip::File.open(zip_path) do |zip_file|
        zip_file.each do |entry|
          target_file = File.join(extract_path, entry.name)
          FileUtils.mkdir_p(File.dirname(target_file))
          zip_file.extract(entry, target_file) unless File.exist?(target_file)
        end
      end
    end

    def self.image_output_path(output_dir, emoji_name, fitzpatrick_level)
      if fitzpatrick_level.nil? || fitzpatrick_level == 1
        File.join(output_dir, "#{emoji_name}.png")
      else
        File.join(output_dir, emoji_name, "#{fitzpatrick_level}.png")
      end
    end

    def self.process_images(asset_path, output_dir)
      Dir
        .glob(File.join(asset_path, "*.png"))
        .each do |file|
          filename = File.basename(file, ".png").downcase
          codepoints = filename.split("-")

          fitzpatrick_level = nil
          base_codepoints =
            codepoints.reject do |cp|
              if FITZPATRICK_SCALE.key?(cp)
                fitzpatrick_level = FITZPATRICK_SCALE[cp]
                true
              else
                false
              end
            end

          base_unicode = base_codepoints.map { |cp| cp.to_i(16) }
          emoji = base_unicode.pack("U*") if base_unicode.all? { |cp| cp <= 0x10FFFF }
          emoji_name = SUPPORTED_EMOJIS[emoji] if emoji && SUPPORTED_EMOJIS.key?(emoji)

          next unless emoji_name

          output_path = image_output_path(output_dir, emoji_name, fitzpatrick_level)
          FileUtils.mkdir_p(File.dirname(output_path))
          FileUtils.cp(file, output_path)

          if EMOJI_ALIASES.key?(emoji_name)
            EMOJI_ALIASES[emoji_name].each do |alias_name|
              alias_output_path = image_output_path(output_dir, alias_name, fitzpatrick_level)
              FileUtils.mkdir_p(File.dirname(alias_output_path))
              FileUtils.cp(file, alias_output_path)
            end
          end

          puts "Saved: #{output_path}"
        end
    end
  end
end
