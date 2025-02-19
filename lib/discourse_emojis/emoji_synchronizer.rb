# frozen_string_literal: true

# The EmojiSynchronizer is responsible for ensuring all emoji sets have a complete
# collection of emoji images. It copies any missing emoji files from the unicode
# directory (which serves as the source of truth) to other emoji set directories.
# This includes both base emoji images and their variations (e.g., skin tone variants).
#
# Usage:
#   DiscourseEmojis::EmojiSynchronizer.sync_missing_emojis
#
module DiscourseEmojis
  class EmojiSynchronizer
    UNICODE_DIR = "dist/emoji/unicode"

    def self.sync_missing_emojis
      new.sync_missing_emojis
    end

    def sync_missing_emojis
      emoji_dirs.each { |target_dir| sync_directory(target_dir) }
    end

    private

    def emoji_dirs
      Dir.glob("dist/emoji/*").select { |d| File.directory?(d) && !d.end_with?("/unicode") }
    end

    def unicode_files
      @unicode_files ||= Dir.glob("#{UNICODE_DIR}/*").select { |f| File.file?(f) }
    end

    def sync_directory(target_dir)
      unicode_files.each do |unicode_file|
        sync_file(unicode_file, target_dir)
        sync_variations(unicode_file, target_dir)
      end
    end

    def sync_file(unicode_file, target_dir)
      filename = File.basename(unicode_file)
      target_file = File.join(target_dir, filename)

      return if File.exist?(target_file)

      FileUtils.cp(unicode_file, target_file)
    end

    def sync_variations(unicode_file, target_dir)
      base_name = File.basename(unicode_file, ".png")
      unicode_variations_dir = File.join(UNICODE_DIR, base_name)

      return unless File.directory?(unicode_variations_dir)

      target_variations_dir = File.join(target_dir, base_name)
      FileUtils.mkdir_p(target_variations_dir)

      Dir
        .glob("#{unicode_variations_dir}/*.png")
        .each do |variation_file|
          sync_variation_file(variation_file, target_variations_dir, base_name, target_dir)
        end
    end

    def sync_variation_file(variation_file, target_variations_dir, base_name, target_dir)
      variation_filename = File.basename(variation_file)
      target_variation_file = File.join(target_variations_dir, variation_filename)

      return if File.exist?(target_variation_file)

      puts "Copying #{base_name}/#{variation_filename} from unicode to #{File.basename(target_dir)}"
      FileUtils.cp(variation_file, target_variation_file)
    end
  end
end
