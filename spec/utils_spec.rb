# frozen_string_literal: true

require "rspec"
require "set"
require "discourse_emojis"

RSpec.describe DiscourseEmojis::Utils do
  describe ".can_be_toned?" do
    it "returns true for an emoji with a modifier base" do
      expect(described_class.can_be_toned?("🏃")).to eq(true)
    end

    it "returns false for an emoji without a modifier base" do
      expect(described_class.can_be_toned?("😀")).to eq(false)
    end

    it "returns false for emojis in the two_family_emojis set" do
      expect(described_class.can_be_toned?("👩‍👦")).to eq(false)
      expect(described_class.can_be_toned?("👩‍👧")).to eq(false)
      expect(described_class.can_be_toned?("👨‍👦")).to eq(false)
      expect(described_class.can_be_toned?("👨‍👧")).to eq(false)
    end

    it "returns false when there are more than two bases" do
      expect(described_class.can_be_toned?("👩‍👩‍👦‍👦")).to eq(false)
      expect(described_class.can_be_toned?("👨️‍👨️‍👦️")).to eq(false)
    end
  end

  describe ".force_emoji_presentation" do
    it "adds FE0F to a single codepoint emoji that matches \\p{Emoji}" do
      emoji = "✔"
      result = described_class.force_emoji_presentation(emoji)
      expect(result).to eq("✔\u{FE0F}")
    end

    it "does not add FE0F if it is already present" do
      emoji = "✔\u{FE0F}"
      result = described_class.force_emoji_presentation(emoji)
      expect(result).to eq(emoji)
    end

    it "adds FE0F before keycap combining" do
      emoji = "1\u{20E3}"
      result = described_class.force_emoji_presentation(emoji)
      expect(result).to eq("1\u{FE0F}\u{20E3}")
    end

    it "handles ZWJ sequences and inserts FE0F where needed" do
      emoji = "🧑\u{200D}💻"
      result = described_class.force_emoji_presentation(emoji)
      expect(result).to eq("🧑\u{FE0F}\u{200D}💻\u{FE0F}")
    end

    it "adds FE0F to gender symbols" do
      male_symbol = "\u{2642}"
      female_symbol = "\u{2640}"

      result_male = described_class.force_emoji_presentation(male_symbol)
      result_female = described_class.force_emoji_presentation(female_symbol)

      expect(result_male).to eq("\u{2642}\u{FE0F}")
      expect(result_female).to eq("\u{2640}\u{FE0F}")
    end
  end
end
