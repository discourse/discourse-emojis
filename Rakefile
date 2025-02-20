# frozen_string_literal: true

require "rake"
require "bundler/gem_tasks"
require "discourse_emojis"

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
  end
end
