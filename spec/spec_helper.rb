RSpec.configure do |config|
  config.before(:suite) { FileUtils.mkdir_p("dist/emoji/fluentui") }

  config.after(:suite) { FileUtils.rm_rf("dist/emoji/fluentui") }
end
