# frozen_string_literal: true

module DiscourseEmojis
  SKIN_TONE_RANGE = "\u{1F3FB}-\u{1F3FF}".freeze
  EMOJI_PRESENTATION_SELECTOR = "\u{FE0F}".freeze
  KEYCAP_COMBINING = "\u{20E3}".freeze

  class Utils
    def self.can_be_toned?(emoji)
      two_family_emojis = %w[👩‍👦 👩‍👧 👨‍👧 👨‍👦].to_set

      emoji = emoji.gsub(/[#{SKIN_TONE_RANGE}]/, "")

      emoji_base_modifier_regex = /\p{Emoji_Modifier_Base}/
      modifiable_components = emoji.scan(emoji_base_modifier_regex).length

      return false if modifiable_components > 2 || two_family_emojis.include?(emoji)

      emoji.chars.any? { |code_point| code_point.match?(emoji_base_modifier_regex) }
    end

    def self.force_emoji_presentation(emoji)
      emoji
        .scan(/\X/) # Splits into grapheme clusters
        .map do |cluster|
          components = cluster.split("\u{200D}") # Handle ZWJ sequences

          components.map! do |part|
            # Keycap (0️⃣, 1️⃣, etc.): Ensure FE0F is placed before U+20E3
            if part.match?(/^[0-9#*]#{KEYCAP_COMBINING}$/) &&
                 !part.include?(EMOJI_PRESENTATION_SELECTOR)
              part.insert(1, EMOJI_PRESENTATION_SELECTOR) # Insert FE0F after digit/hash/star
            elsif part.codepoints.size == 1 && part.match?(/\p{Emoji}/) &&
                  !part.include?(EMOJI_PRESENTATION_SELECTOR)
              part + EMOJI_PRESENTATION_SELECTOR
            elsif part == "\u{2642}" || part == "\u{2640}" # Ensure gender symbols get FE0F
              part + EMOJI_PRESENTATION_SELECTOR
            else
              part
            end
          end

          components.join("\u{200D}") # Reassemble ZWJ sequences
        end
        .join
    end
  end
end
