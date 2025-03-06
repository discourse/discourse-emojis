# frozen_string_literal: true

module DiscourseEmojis
  # The EmojiAliasCreator is responsible for creating alias files for emojis
  # based on the aliases defined in EMOJI_ALIASES. It handles both regular emojis
  # and tonable emojis.
  #
  # Usage:
  # To create emoji alias files, call the `create_aliases` method:
  #
  # DiscourseEmojis::EmojiAliasCreator.create_aliases

  class EmojiAliasCreator
    def self.create_aliases
      new.create_aliases
    end

    def create_aliases
      emoji_dirs.each { |dir| create_aliases_for_directory(dir) }
    end

    private

    def emoji_dirs
      Dir.glob("#{DiscourseEmojis.path_for_emojis}/*").select { |d| File.directory?(d) }
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
      FileUtils.cd(dir) do
        FileUtils.ln_s("#{original_name}.png", "#{alias_name}.png")

        variations_dir = File.join(dir, original_name)
        return if !File.directory?(variations_dir)

        create_tone_variations(original_name, alias_name)
      end
    end

    def create_tone_variations(original_name, alias_name)
      FileUtils.ln_s(original_name, alias_name, force: true)
    end
  end
end
