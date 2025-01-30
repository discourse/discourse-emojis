# frozen_string_literal: true

module DiscourseEmojis
  VERSION = "0.0.1"

  def self.path_for_emojis
    File.expand_path("../../vendor/emoji", __FILE__)
  end
end
