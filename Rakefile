require "rake"

# Load all tasks from lib/tasks/
Dir.glob(File.expand_path("lib/tasks/**/*.rake", __dir__)).each { |r| load r }

desc "Generate all emoji sets"
task :generate do
  Rake::Task["db"].invoke

  Rake::Task["noto_emoji"].invoke
  Rake::Task["unicode"].invoke
  Rake::Task["twemoji"].invoke
  Rake::Task["openmoji"].invoke
end
