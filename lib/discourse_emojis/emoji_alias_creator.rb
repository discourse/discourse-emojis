# frozen_string_literal: true

module DiscourseEmojis
  # The EmojiAliasCreator is responsible for creating alias files for emojis
  # based on the aliases defined in EMOJI_ALIASES. It handles both regular emojis
  # and tonable emojis (those with skin tone variations).
  #
  # Usage:
  #   DiscourseEmojis::EmojiAliasCreator.create_aliases
  #
  class EmojiAliasCreator
    def self.create_aliases
      new.create_aliases
    end

    def create_aliases
      emoji_dirs.each { |dir| create_aliases_for_directory(dir) }
    end

    private

    def emoji_dirs
      Dir.glob("#{EMOJI_DIST_PATH}/*").select { |d| File.directory?(d) && !d.end_with?("/unicode") }
    end

    def create_aliases_for_directory(dir)
      Dir
        .glob("#{dir}/*.png")
        .each do |emoji_file|
          base_name = File.basename(emoji_file, ".png")
          create_aliases_for_emoji(dir, base_name) if EMOJI_ALIASES[base_name]
        end
    end

    def create_aliases_for_emoji(dir, base_name)
      EMOJI_ALIASES[base_name].each { |alias_name| create_alias_files(dir, base_name, alias_name) }
    end

    def create_alias_files(dir, original_name, alias_name)
      # Create the base emoji alias
      source_file = File.join(dir, "#{original_name}.png")
      target_file = File.join(dir, "#{alias_name}.png")

      return if File.exist?(target_file)

      FileUtils.cp(source_file, target_file)

      # Handle skin tone variations if they exist
      variations_dir = File.join(dir, original_name)
      return unless File.directory?(variations_dir)

      create_tone_variations(dir, variations_dir, alias_name)
    end

    def create_tone_variations(dir, variations_dir, alias_name)
      target_variations_dir = File.join(dir, alias_name)
      FileUtils.mkdir_p(target_variations_dir)

      Dir
        .glob("#{variations_dir}/*.png")
        .each do |variation_file|
          variation_name = File.basename(variation_file)
          target_variation_file = File.join(target_variations_dir, variation_name)

          next if File.exist?(target_variation_file)

          FileUtils.cp(variation_file, target_variation_file)
        end
    end
  end
end
