# frozen_string_literal: true
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) if !$LOAD_PATH.include?(lib)
require "discourse_emojis"

Gem::Specification.new do |s|
  s.name = "discourse-emojis"
  s.version = DiscourseEmojis::VERSION
  s.summary = "Bundle of emojis sets for Discourse"
  s.description =
    "Bundle of emojis sets for Discourse"
  s.authors = ["Joffrey Jaffeux"]
  s.email = "joffrey.jaffeux@discourse.org"
  s.files =
    Dir[
      "lib/*.rb",
      "vendor/assets/emojis/**/*.png",
    ]
  s.homepage = "https://github.com/discourse/discourse-emojis"
  s.license = "MIT"

  s.required_ruby_version = ">= 3.2.0"

  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rubyzip", "~> 2.4"
  s.add_development_dependency "rubocop-discourse", "~> 3.9"
end
