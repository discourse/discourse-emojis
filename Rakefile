# frozen_string_literal: true

require "rake"

Dir.glob(File.expand_path("lib/tasks/**/*.rake", __dir__)).each { |task| import(task) }

desc "Generate all emoji sets"
task :generate do
  FileUtils.rm_rf("dist")
  FileUtils.mkdir_p("dist")

  Rake::Task["db"].invoke

  # needs to be run first as we use the standard
  # if it doesn't exist in the set
  Rake::Task["unicode"].invoke

  Rake::Task["fluentui_emoji"].invoke
  Rake::Task["noto_emoji"].invoke
  Rake::Task["twemoji"].invoke
  Rake::Task["openmoji"].invoke

  Rake::Task["missing_emojis"].invoke
end
