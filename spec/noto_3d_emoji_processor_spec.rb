# frozen_string_literal: true

require "rspec"
require "discourse_emojis"
require "discourse_emojis/constants"
require "discourse_emojis/utils"
require "discourse_emojis/codepoints_emoji_processor"
require "discourse_emojis/noto_3d_emoji_processor"
require "discourse_emojis/emoji_alias_creator"
require "discourse_emojis/emoji_synchronizer"

RSpec.describe DiscourseEmojis::Noto3DEmojiProcessor do
  describe ".process" do
    it "maps base, keycap, flag, and uniform skin-tone PNGs while skipping mixed tones" do
      Dir.mktmpdir do |root|
        emoji_dir = File.join(root, "emoji")
        unicode_dir = File.join(emoji_dir, "unicode")
        FileUtils.mkdir_p(unicode_dir)
        File.write(File.join(unicode_dir, "grinning.png"), "unicode grinning")
        File.write(File.join(unicode_dir, "fallback_only.png"), "unicode fallback")
        stub_const("DiscourseEmojis::EmojiSynchronizer::UNICODE_DIR", unicode_dir)

        output_dir = File.join(emoji_dir, "noto_3d")
        allow(DiscourseEmojis).to receive(:path_for_emojis).and_return(emoji_dir)

        mapping = {
          "😀️" => "grinning",
          "👍️" => "+1",
          "1️⃣" => "one",
          "🇺🇸" => "united_states",
          "👨️‍❤️‍👨️" => "couple_with_heart_man_man",
          "👯️" => "people_with_bunny_ears",
        }
        mapping_path = File.join(root, "emoji_to_name.json")
        tones_path = File.join(root, "tonable_emojis.json")
        File.write(mapping_path, mapping.to_json)
        File.write(tones_path, %w[+1 couple_with_heart_man_man].to_json)
        stub_const("DiscourseEmojis::CodepointsEmojiProcessor::EMOJI_TO_NAME_PATH", mapping_path)
        stub_const("DiscourseEmojis::CodepointsEmojiProcessor::TONABLE_EMOJIS_PATH", tones_path)

        source_dir = File.join(root, "3D", "png", "72")
        FileUtils.mkdir_p(source_dir)
        {
          "emoji_u1f600.png" => "3d grinning",
          "emoji_u1f44d.png" => "3d thumbs up",
          "emoji_u1f44d_1f3fb.png" => "3d thumbs up t2",
          "emoji_u0031_20e3.png" => "3d keycap 1",
          "emoji_u1f1fa_1f1f8.png" => "3d us flag",
          "emoji_u1f468_200d_2764_200d_1f468.png" => "3d couple base",
          "emoji_u1f468_1f3fb_200d_2764_200d_1f468_1f3fb.png" => "3d couple uniform t2",
          "emoji_u1f468_1f3ff_200d_2764_200d_1f468_1f3fb.png" => "3d couple mixed t6+t2",
          "emoji_u1f46f.png" => "3d bunny ears",
          "emoji_u1f46f_1f3fb.png" => "3d bunny ears non-tonable t2",
          "emoji_u1f6d9.png" => "3d unsupported emoji 18",
        }.each { |filename, content| File.binwrite(File.join(source_dir, filename), content) }

        described_class.process(source_dir)

        DiscourseEmojis::EmojiAliasCreator.create_aliases
        DiscourseEmojis::EmojiAliasCreator.create_aliases
        DiscourseEmojis::EmojiSynchronizer.sync_missing_emojis

        expect(File.binread(File.join(output_dir, "grinning.png"))).to eq("3d grinning")
        expect(File.binread(File.join(output_dir, "+1.png"))).to eq("3d thumbs up")
        expect(File.binread(File.join(output_dir, "+1/2.png"))).to eq("3d thumbs up t2")
        expect(File.binread(File.join(output_dir, "thumbs_up.png"))).to eq("3d thumbs up")
        expect(File.binread(File.join(output_dir, "thumbs_up/2.png"))).to eq("3d thumbs up t2")
        expect(File.binread(File.join(output_dir, "one.png"))).to eq("3d keycap 1")
        expect(File.binread(File.join(output_dir, "keycap_1.png"))).to eq("3d keycap 1")
        expect(File.binread(File.join(output_dir, "united_states.png"))).to eq("3d us flag")
        expect(File.binread(File.join(output_dir, "us.png"))).to eq("3d us flag")
        expect(File.binread(File.join(output_dir, "couple_with_heart_man_man.png"))).to eq(
          "3d couple base",
        )
        expect(File.binread(File.join(output_dir, "couple_with_heart_man_man/2.png"))).to eq(
          "3d couple uniform t2",
        )
        expect(File.binread(File.join(output_dir, "people_with_bunny_ears.png"))).to eq(
          "3d bunny ears",
        )
        expect(File.exist?(File.join(output_dir, "people_with_bunny_ears/2.png"))).to eq(false)
        expect(File.symlink?(File.join(output_dir, "fallback_only.png"))).to eq(true)
        expect(File.binread(File.join(output_dir, "fallback_only.png"))).to eq("unicode fallback")
      end
    end

    it "uses a sparse git checkout with LFS smudge disabled when no source_dir is provided" do
      Dir.mktmpdir do |root|
        emoji_dir = File.join(root, "emoji")
        allow(DiscourseEmojis).to receive(:path_for_emojis).and_return(emoji_dir)

        mapping_path = File.join(root, "emoji_to_name.json")
        tones_path = File.join(root, "tonable_emojis.json")
        File.write(mapping_path, { "😀️" => "grinning" }.to_json)
        File.write(tones_path, [].to_json)
        stub_const("DiscourseEmojis::CodepointsEmojiProcessor::EMOJI_TO_NAME_PATH", mapping_path)
        stub_const("DiscourseEmojis::CodepointsEmojiProcessor::TONABLE_EMOJIS_PATH", tones_path)

        commands = []
        allow(Open3).to receive(:capture3) do |env, command, *args|
          expect(env).to eq({ "GIT_LFS_SKIP_SMUDGE" => "1" })
          expect(command).to eq("git")
          commands << args

          if args.first == "clone"
            checkout_dir = args.last
            asset_dir = File.join(checkout_dir, described_class::ASSET_SUBDIR)
            FileUtils.mkdir_p(asset_dir)
            File.binwrite(File.join(asset_dir, "emoji_u1f600.png"), "3d grinning")
          end

          ["", "", instance_double(Process::Status, success?: true)]
        end

        described_class.process

        expect(commands.size).to eq(3)
        expect(commands[0]).to include("--sparse", "--no-checkout", described_class::TAG)
        expect(commands[1]).to include("sparse-checkout", "set", "--no-cone", "/3D/png/72/")
        expect(commands[2]).to include("checkout")
        expect(File.binread(File.join(emoji_dir, "noto_3d", "grinning.png"))).to eq("3d grinning")
      end
    end
  end
end
