# frozen_string_literal: true

require "rspec"
require "discourse_emojis"
require "discourse_emojis/constants"
require "discourse_emojis/utils"
require "discourse_emojis/codepoints_emoji_processor"
require "discourse_emojis/noto_animated_emoji_processor"
require "discourse_emojis/emoji_alias_creator"
require "discourse_emojis/emoji_synchronizer"

RSpec.describe DiscourseEmojis::NotoAnimatedEmojiProcessor do
  describe ".process" do
    it "preserves original WebPs and maps names, skin tones, and aliases without static fallbacks" do
      Dir.mktmpdir do |root|
        emoji_dir = File.join(root, "emoji")
        noto_dir = File.join(emoji_dir, "noto")
        FileUtils.mkdir_p(File.join(noto_dir, "+1"))
        %w[grinning.png smile.png +1.png +1/2.png +1/3.png].each do |file|
          File.write(File.join(noto_dir, file), "static")
        end
        output_dir = File.join(emoji_dir, "noto_animated")
        FileUtils.mkdir_p(output_dir)
        mapping = { "😀️" => "grinning", "😄️" => "smile", "👍️" => "+1", "©️" => "copyright" }
        allow(DiscourseEmojis).to receive(:path_for_emojis).and_return(emoji_dir)
        mapping_path = File.join(root, "emoji_to_name.json")
        tones_path = File.join(root, "tonable_emojis.json")
        File.write(mapping_path, mapping.to_json)
        File.write(tones_path, ["+1"].to_json)
        stub_const("DiscourseEmojis::CodepointsEmojiProcessor::EMOJI_TO_NAME_PATH", mapping_path)
        stub_const("DiscourseEmojis::CodepointsEmojiProcessor::TONABLE_EMOJIS_PATH", tones_path)
        icons =
          %w[1f600 1f44d 1f44d_1f3fb a9_fe0f 10ffff].map { |codepoint| { codepoint: codepoint } }
        bodies = { described_class::METADATA_URL => { icons: icons }.to_json }
        %w[1f600 1f44d 1f44d_1f3fb 00a9_fe0f].each do |codepoint|
          bodies["#{described_class::ASSET_URL}/#{codepoint}/512.webp"] = "original webp"
        end
        allow(Net::HTTP).to receive(:get_response) do |uri|
          response = Net::HTTPOK.new("1.1", "200", "OK")
          allow(response).to receive(:body).and_return(bodies.fetch(uri.to_s))
          response
        end

        described_class.process

        DiscourseEmojis::EmojiAliasCreator.create_aliases
        DiscourseEmojis::EmojiSynchronizer.sync_missing_emojis

        expect(File.binread(File.join(output_dir, "copyright.webp"))).to eq("original webp")
        expect(File.binread(File.join(output_dir, "grinning.webp"))).to eq("original webp")
        expect(File.binread(File.join(output_dir, "+1/2.webp"))).to eq("original webp")
        expect(File.binread(File.join(output_dir, "thumbs_up/2.webp"))).to eq("original webp")
        expect(File.exist?(File.join(output_dir, "thumbs_up/3.webp"))).to eq(false)
        expect(File.exist?(File.join(output_dir, "smile.webp"))).to eq(false)
        expect(Dir.glob(File.join(output_dir, "**", "*.png"))).to eq([])
      end
    end
  end
end
