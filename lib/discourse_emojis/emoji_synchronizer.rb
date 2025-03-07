# frozen_string_literal: true

module DiscourseEmojis
  class EmojiSynchronizer
    # The EmojiSynchronizer class is responsible for synchronizing missing emoji
    # files across different directories. It ensures that all non-Unicode emoji
    # directories contain the necessary emoji symlinks to the Unicode directory.
    #
    # Constants:
    # - UNICODE_DIR: The directory where Unicode emoji files are stored.
    #
    # Usage:
    # To synchronize missing emoji files, call the `sync_missing_emojis` method:
    #
    # DiscourseEmojis::EmojiSynchronizer.sync_missing_emojis

    UNICODE_DIR = "dist/emoji/unicode"

    def self.sync_missing_emojis
      new.sync_missing_emojis
    end

    def sync_missing_emojis
      emoji_dirs.each { |target_dir| sync_directory(target_dir) }
    end

    private

    def emoji_dirs
      Dir
        .glob("dist/emoji/*")
        .select { |d| File.directory?(d) && !d.end_with?("/unicode") && !File.symlink?(d) }
    end

    def unicode_files
      @unicode_files ||= Dir.glob(File.join(UNICODE_DIR, "*")).select { |f| File.file?(f) }
    end

    def sync_directory(target_dir)
      files = unicode_files
      FileUtils.cd(target_dir) do
        files.each do |unicode_file|
          filename = File.basename(unicode_file)
          sync_file(filename)
          sync_variations(filename)
        end
      end
    end

    def sync_file(filename)
      source = File.join("..", "unicode", filename)
      return if !File.exist?(source)
      return if File.exist?(filename)
      FileUtils.ln_s(source, filename)
    end

    def sync_variations(filename)
      base_name = File.basename(filename, ".png")

      (2..6).each do |tone|
        source = File.join("..", "unicode", base_name, "#{tone}.png")
        target = File.join(base_name, "#{tone}.png")
        next if !File.exist?(source)
        next if File.exist?(target)
        FileUtils.mkdir_p(base_name)

        # we checked that unicode has the file, so we can safely link
        # but at this point we are one level deeper in the directory
        # so we need to go back one level
        FileUtils.ln_s(File.join("..", source), target)
      end
    end
  end
end
