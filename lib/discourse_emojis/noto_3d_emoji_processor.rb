# frozen_string_literal: true

require "open3"
require "tmpdir"

module DiscourseEmojis
  class Noto3DEmojiProcessor < CodepointsEmojiProcessor
    REPO_URL = "https://github.com/googlefonts/noto-emoji.git"
    TAG = "v2026-09-24-unicode18_0"
    ASSET_SUBDIR = File.join("3D", "png", "72")

    class << self
      def process(source_dir = nil)
        output_dir = File.join(DiscourseEmojis.path_for_emojis, "noto_3d")

        if source_dir
          process_images(source_dir, output_dir)
        else
          with_sparse_checkout do |checkout_dir|
            process_images(File.join(checkout_dir, ASSET_SUBDIR), output_dir)
          end
        end
      end

      private

      def with_sparse_checkout
        Dir.mktmpdir do |temp_dir|
          checkout_dir = File.join(temp_dir, "noto-emoji")
          run_git(
            "clone",
            "--depth",
            "1",
            "--filter=blob:none",
            "--sparse",
            "--no-checkout",
            "--branch",
            TAG,
            REPO_URL,
            checkout_dir,
          )
          run_git("-C", checkout_dir, "sparse-checkout", "set", "--no-cone", "/#{ASSET_SUBDIR}/")
          run_git("-C", checkout_dir, "checkout")
          yield(checkout_dir)
        end
      end

      def run_git(*args)
        _, error, status = Open3.capture3({ "GIT_LFS_SKIP_SMUDGE" => "1" }, "git", *args)
        raise "Failed to run git #{args.first}: #{error}" if !status.success?
      end
    end
  end
end
