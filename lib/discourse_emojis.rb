# frozen_string_literal: true

require "discourse_emojis/railtie"

module DiscourseEmojis
  def self.path_for_emojis
    File.expand_path("../../vendor/emoji", __FILE__)
  end
end
