# frozen_string_literal: true

require "rails_helper"
require "json"
require "fileutils"
require_relative "../../lib/discourse_emojis/fluentui_emoji_processor"

RSpec.describe DiscourseEmojis::FluentUIEmojiProcessor do
  let(:assets_dir) { Dir.mktmpdir }
  let(:output_dir) { Dir.mktmpdir }
  let(:supported_emojis) { { "😀" => "grinning" } }
  let(:processor) { described_class.new(assets_dir, supported_emojis, output_dir) }
  let(:emoji_dir) { File.join(assets_dir, "grinning") }

  before do
    FileUtils.mkdir_p(assets_dir)
    FileUtils.mkdir_p(output_dir)
    allow(FileUtils).to receive(:mkdir_p).and_call_original
  end

  after do
    FileUtils.remove_entry(assets_dir) if File.exist?(assets_dir)
    FileUtils.remove_entry(output_dir) if File.exist?(output_dir)
  end

  describe "#process_all" do
    before do
      FileUtils.mkdir_p(emoji_dir)
      File.write(File.join(emoji_dir, "metadata.json"), { glyph: "😀" }.to_json)
    end

    context "when processing regular emoji" do
      before do
        color_dir = File.join(emoji_dir, "Color")
        FileUtils.mkdir_p(color_dir)
        FileUtils.touch(File.join(color_dir, "grinning.svg"))
        allow(processor).to receive(:convert_svg_to_png).and_call_original
        allow(FileUtils).to receive(:mkdir_p)
        allow(processor).to receive(:system).and_return(true)
      end

      it "converts the emoji to png" do
        processor.process_all

        expect(processor).to have_received(:system).with(
          "rsvg-convert",
          "-w",
          "72",
          "-h",
          "72",
          "--keep-aspect-ratio",
          "--dpi-x",
          "300",
          "--dpi-y",
          "300",
          "-o",
          File.join(output_dir, "grinning.png"),
          anything, # Don't care about exact source path
        )
      end
    end

    context "when processing skin tone variations" do
      before do
        create_tone_variations
        allow(processor).to receive(:convert_svg_to_png).and_return(true)
      end

      it "converts SVGs to PNGs in the correct locations" do
        processor.process_all

        # Verify default version conversion
        expect(processor).to have_received(:convert_svg_to_png).with(
          File.join(emoji_dir, "Default", "Color", "grinning.svg"),
          File.join(output_dir, "grinning.png"),
        )

        # Verify skin tone variation conversions
        described_class::SKIN_TONE_LEVELS.each do |tone, level|
          expect(processor).to have_received(:convert_svg_to_png).with(
            File.join(emoji_dir, tone, "Color", "grinning_color_#{tone.downcase}.svg"),
            File.join(output_dir, "grinning", "#{level}.png"),
          )
        end
      end
    end
  end

  describe "#valid_metadata?" do
    context "when metadata is valid" do
      it "returns true" do
        metadata = { "glyph" => "😀" }
        expect(processor.send(:valid_metadata?, metadata)).to be true
      end
    end

    context "when metadata is invalid" do
      it "returns false for nil" do
        expect(processor.send(:valid_metadata?, nil)).to be false
      end

      it "returns false for missing glyph" do
        expect(processor.send(:valid_metadata?, {})).to be false
      end

      it "returns false for unsupported emoji" do
        metadata = { "glyph" => "🤔" }
        expect(processor.send(:valid_metadata?, metadata)).to be false
      end
    end
  end

  describe "#convert_svg_to_png" do
    let(:svg_path) { "test.svg" }
    let(:output_png) { "test.png" }
    let(:conversion_args) do
      [
        "rsvg-convert",
        "-w",
        "72",
        "-h",
        "72",
        "--keep-aspect-ratio",
        "--dpi-x",
        "300",
        "--dpi-y",
        "300",
        "-o",
        output_png,
        svg_path,
      ]
    end

    context "when conversion succeeds" do
      before { allow(processor).to receive(:system).and_return(true) }

      it "calls system with correct parameters" do
        processor.send(:convert_svg_to_png, svg_path, output_png)
        expect(processor).to have_received(:system).with(*conversion_args)
      end
    end

    context "when conversion fails" do
      before { allow(processor).to receive(:system).and_return(false) }

      it "outputs error message" do
        expect { processor.send(:convert_svg_to_png, svg_path, output_png) }.to output(
          /Conversion failed with status: unknown/,
        ).to_stdout
      end
    end
  end

  private

  def create_tone_variations
    # Create Default directory
    default_dir = File.join(emoji_dir, "Default", "Color")
    FileUtils.mkdir_p(default_dir)
    FileUtils.touch(File.join(default_dir, "grinning.svg"))

    # Create tone variations
    described_class::SKIN_TONE_LEVELS.each do |tone, _|
      color_dir = File.join(emoji_dir, tone, "Color")
      FileUtils.mkdir_p(color_dir)
      FileUtils.touch(File.join(color_dir, "grinning_color_#{tone.downcase}.svg"))
    end
  end
end
