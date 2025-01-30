require 'rake'
require 'open-uri'
require 'zip'
require 'fileutils'
require 'tmpdir'
require 'json'

namespace :openmoji do
  SETS = [
    {name: 'openmoji-black', url: 'https://github.com/hfg-gmuend/openmoji/releases/latest/download/openmoji-72x72-black.zip'},
    {name: 'openmoji-color', url: 'https://github.com/hfg-gmuend/openmoji/releases/latest/download/openmoji-72x72-black.zip'},
  ]

  FITZPATRICK_SCALE = {
    "1F3FB" => 1,
    "1F3FC" => 2,
    "1F3FD" => 3,
    "1F3FE" => 4,
    "1F3FF" => 5
  }

  desc "Download and process OpenMoji ZIP archive"
  task :process do
    SETS.each do |set|
      FileUtils.rm_rf(File.expand_path("vendor/emoji/#{set[:name]}", __dir__))

      zip_path = File.join(Dir.tmpdir, 'openmoji.zip')
      extract_path = Dir.mktmpdir
      db_path = File.expand_path('db.json', __dir__)
      output_dir = File.expand_path("vendor/emoji/#{set[:name]}", __dir__)

      # Load db.json
      db = JSON.parse(File.read(db_path))


      # Download the ZIP file
      URI.open(set[:url]) do |download|
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
          if FITZPATRICK_SCALE.key?(cp)
            fitzpatrick_level = FITZPATRICK_SCALE[cp]
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
        if fitzpatrick_level
          output_path = File.join(output_dir, emoji_name, "#{fitzpatrick_level}.png")
        else
          output_path = File.join(output_dir, "#{emoji_name}.png")
        end

        # Ensure directory exists before saving
        FileUtils.mkdir_p(File.dirname(output_path))
        FileUtils.cp(file, output_path)

        puts "Saved: #{output_path}"
      end

      FileUtils.remove_entry(extract_path)
      FileUtils.remove_entry(zip_path)
    end
  end
end
