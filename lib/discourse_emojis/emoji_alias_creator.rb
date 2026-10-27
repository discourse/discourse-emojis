# frozen_string_literal: true

module DiscourseEmojis
  # The EmojiAliasCreator is responsible for creating alias symlinks for emojis
  # based on the aliases defined in EMOJI_ALIASES. It handles both regular emojis
  # and tonable emojis.
  #
  # Usage:
  # To create emoji alias symlinks, call the `create_aliases` method:
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
        .glob("#{dir}/*.{png,webp}")
        .each do |emoji_file|
          extension = File.extname(emoji_file)
          base_name = File.basename(emoji_file, extension)
          create_aliases_for_emoji(dir, base_name, extension) if EMOJI_ALIASES[base_name]
        end
    end

    def create_aliases_for_emoji(dir, base_name, extension)
      EMOJI_ALIASES[base_name].each do |alias_name|
        create_alias_files(dir, base_name, alias_name, extension)
      end
    end

    def create_alias_files(dir, original_name, alias_name, extension)
      FileUtils.cd(dir) do
        FileUtils.ln_s("#{original_name}#{extension}", "#{alias_name}#{extension}")

        variations_dir = File.join(dir, original_name)
        return if !File.directory?(variations_dir)

        create_tone_variations(original_name, alias_name, extension)
      end
    end

    def create_tone_variations(original_name, alias_name, extension)
      FileUtils.mkdir_p(alias_name)

      (2..6).each do |tone|
        if extension == ".webp" && !File.exist?(File.join(original_name, "#{tone}#{extension}"))
          next
        end

        FileUtils.ln_s(
          File.join("..", original_name, "#{tone}#{extension}"),
          File.join(alias_name, "#{tone}#{extension}"),
        )
      end
    end
  end
end
