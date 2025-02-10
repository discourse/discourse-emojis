# frozen_string_literal: true

require "rails_helper"
require "rake"
require "json"
require "fileutils"
require_relative "../../../lib/discourse_emojis/fluentui_emoji_processor"

RSpec.describe "fluentui_emoji rake task" do
  before(:all) do
    Rake.application.rake_require "tasks/fluentui_emoji"
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task["fluentui_emoji"] }
  let(:zip_processor) { DiscourseEmojis::ZipProcessor }
  let(:test_zip_path) { File.join(Dir.tmpdir, "fluentui.zip") }
  let(:test_extract_path) { Dir.mktmpdir }
  let(:test_assets_dir) { File.join(test_extract_path, "fluentui-emoji-main", "assets") }

  before do
    # Stub JSON parsing of supported emojis
    allow(JSON).to receive(:parse).and_return({ "😀" => "grinning" })

    # Stub FileUtils to prevent actual file operations
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:remove_entry)

    # Stub system call for image conversion
    allow_any_instance_of(DiscourseEmojis::FluentUIEmojiProcessor).to receive(:system).and_return(
      true,
    )
  end

  after do
    FileUtils.remove_entry(test_extract_path) if File.exist?(test_extract_path)
    FileUtils.remove_entry(test_zip_path) if File.exist?(test_zip_path)
  end

  it "processes emojis successfully" do
    # Stub ZipProcessor methods
    expect(zip_processor).to receive(:download)
    expect(zip_processor).to receive(:extract)

    # Stub processor
    processor_mock = instance_double(DiscourseEmojis::FluentUIEmojiProcessor)
    expect(DiscourseEmojis::FluentUIEmojiProcessor).to receive(:new).and_return(processor_mock)
    expect(processor_mock).to receive(:process_all)

    # Run the task
    task.execute
  end
end
