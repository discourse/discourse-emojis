# frozen_string_literal: true

require "rake"
require "bundler/gem_tasks"

Dir.glob(File.expand_path("lib/tasks/**/*.rake", __dir__)).each { |task| import(task) }

desc "Generate all emoji sets"
task :generate do
  FileUtils.rm_rf("dist")
  FileUtils.mkdir_p("dist")

  Rake::Task["db"].invoke

  Rake::Task["fluentui_emoji"].invoke
  Rake::Task["noto_emoji"].invoke
  Rake::Task["twemoji"].invoke
  Rake::Task["openmoji"].invoke
  Rake::Task["unicode"].invoke # used as fallback for other sets

  Rake::Task["aliases"].invoke
  Rake::Task["missing_emojis"].invoke
end
