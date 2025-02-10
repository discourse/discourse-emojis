# frozen_string_literal: true

task :missing_emojis do
  require "fileutils"

  # Get all emoji directories except unicode
  emoji_dirs =
    Dir.glob("dist/emoji/*").select { |d| File.directory?(d) && !d.end_with?("/unicode") }
  unicode_dir = "dist/emoji/unicode"

  # Get all unicode emoji files (non-directory)
  unicode_files = Dir.glob("#{unicode_dir}/*").select { |f| File.file?(f) }

  emoji_dirs.each do |target_dir|
    unicode_files.each do |unicode_file|
      filename = File.basename(unicode_file)
      target_file = File.join(target_dir, filename)

      # If file doesn't exist in target directory, copy it from unicode
      if !File.exist?(target_file)
        puts "Copying #{filename} from unicode to #{File.basename(target_dir)}"
        FileUtils.cp(unicode_file, target_file)
      end

      # Handle skin tone variations if they exist
      base_name = filename.sub(".png", "")
      unicode_variations_dir = File.join(unicode_dir, base_name)

      if File.directory?(unicode_variations_dir)
        target_variations_dir = File.join(target_dir, base_name)
        FileUtils.mkdir_p(target_variations_dir)

        Dir
          .glob("#{unicode_variations_dir}/*.png")
          .each do |variation_file|
            variation_filename = File.basename(variation_file)
            target_variation_file = File.join(target_variations_dir, variation_filename)

            if !File.exist?(target_variation_file)
              puts "Copying #{base_name}/#{variation_filename} from unicode to #{File.basename(target_dir)}"
              FileUtils.cp(variation_file, target_variation_file)
            end
          end
      end
    end
  end
end
