# frozen_string_literal: true

require "fileutils"

task "deprecated_symlinks" do
  SYMLINKS = {
    "dist/emoji/apple" => "dist/emoji/unicode",
    "dist/emoji/facebook_messenger" => "dist/emoji/unicode",
    "dist/emoji/google" => "dist/emoji/noto",
    "dist/emoji/google_classic" => "dist/emoji/noto",
    "dist/emoji/win10" => "dist/emoji/fluentui",
  }

  SYMLINKS.each do |source, target|
    FileUtils.ln_s(source, target) unless File.exist?(target) || File.symlink?(target)
  end
end
