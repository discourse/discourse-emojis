require 'rake'
require 'open-uri'
require 'zip'
require 'fileutils'
require 'tmpdir'
require 'json'

task :openmoji do
  name = "openmoji"
  url = "https://github.com/hfg-gmuend/openmoji/releases/latest/download/openmoji-72x72-color.zip"

  zip_path = File.join(Dir.tmpdir, "#{name}.zip")
  extract_path = Dir.mktmpdir
  db_path = File.expand_path('../../db.json', __dir__)
  output_dir = File.expand_path("../../vendor/emoji/#{name}", __dir__)

  # Load db.json
  db = JSON.parse(File.read(db_path))

  # Fitzpatrick scale Unicode points (1F3FB to 1F3FF)
  fitzpatrick_scale = {
    "1F3FB" => 1,
    "1F3FC" => 2,
    "1F3FD" => 3,
    "1F3FE" => 4,
    "1F3FF" => 5,
  }

  # Download the ZIP file
  URI.open(url) do |download|
    File.open(zip_path, 'wb') { |file| file.write(download.read) }
  end

  # Extract the ZIP file
  Zip::File.open(zip_path) do |zip_file|
    zip_file.each do |entry|
      target_file = File.join(extract_path, entry.name)
      FileUtils.mkdir_p(File.dirname(target_file))
      zip_file.extract(entry, target_file) unless File.exist?(target_file)
    end
  end

  # Process each file
  Dir.glob(File.join(extract_path, '**', '*.png')).each do |file|
    filename = File.basename(file, ".png")
    codepoints = filename.split('-')

    # Determine Fitzpatrick level
    fitzpatrick_level = nil
    base_codepoints = codepoints.reject do |cp|
      if fitzpatrick_scale.key?(cp)
        fitzpatrick_level = fitzpatrick_scale[cp]
        true
      else
        false
      end
    end

    # Convert base Unicode points to an actual emoji
    base_unicode = base_codepoints.map { |cp| cp.to_i(16) }
    emoji = base_unicode.pack('U*') if base_unicode.all? { |cp| cp <= 0x10FFFF }

    # Lookup emoji name in db.json
    emoji_name = db[emoji] if emoji && db.key?(emoji)

    # Skip saving if no emoji name is found
    next unless emoji_name

    # Determine output file path
    if fitzpatrick_level.nil? || fitzpatrick_level == 1
      output_path = File.join(output_dir, "#{emoji_name}.png")
    else
      output_path = File.join(output_dir, emoji_name, "#{fitzpatrick_level}.png")
    end

    # Ensure directory exists before saving
    FileUtils.mkdir_p(File.dirname(output_path))
    FileUtils.cp(file, output_path)

    puts "Saved: #{output_path}"
  end

  # Cleanup
  FileUtils.remove_entry(extract_path)
  FileUtils.remove_entry(zip_path)
end

