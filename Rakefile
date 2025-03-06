# frozen_string_literal: true

require "bundler/inline"

gemfile do
  source "https://rubygems.org"

  gem "rubyzip", "~> 2.4"
  gem "nokogiri", "~> 1.8"
  gem "i18n", "~> 1.14", ">= 1.14.7"
  gem "selenium-webdriver", "~> 4.25"
end

require "rake"
require "bundler/gem_tasks"
require "fileutils"
require "discourse_emojis"
require "discourse_emojis/constants"
require "discourse_emojis/zip_processor"
require "discourse_emojis/emoji_synchronizer"
require "discourse_emojis/unicode_emoji_processor"
require "discourse_emojis/codepoints_emoji_processor"
require "discourse_emojis/fluentui_emoji_processor"
require "discourse_emojis/emoji_alias_creator"
require "discourse_emojis/utils"

Dir.glob(File.expand_path("lib/tasks/**/*.rake", __dir__)).each { |task| import(task) }

namespace :emojis do
  desc "Generate all emoji sets"
  task :generate do
    FileUtils.rm_rf("dist")
    FileUtils.mkdir_p("dist")

    Rake::Task["emojis:db"].invoke

    Rake::Task["emojis:fluentui_emoji"].invoke
    Rake::Task["emojis:noto_emoji"].invoke
    Rake::Task["emojis:twemoji"].invoke
    Rake::Task["emojis:openmoji"].invoke
    Rake::Task["emojis:unicode"].invoke # used as fallback for other sets

    Rake::Task["emojis:aliases"].invoke
    Rake::Task["emojis:missing_emojis"].invoke
    Rake::Task["emojis:deprecated_symlinks"].invoke
  end
end
