# frozen_string_literal: true

module DiscourseFonts
  VERSION = "0.0.1"

  def self.path_for_fonts
    File.expand_path("../../vendor/assets/emojis", __FILE__)
  end
end
