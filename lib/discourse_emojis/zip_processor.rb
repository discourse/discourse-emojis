# frozen_string_literal: true

require "zip"
require "open-uri"
require "fileutils"

module DiscourseEmojis
  class ZipProcessor
    def self.with_extracted_files(url, &block)
      zip_path = File.join(Dir.tmpdir, File.basename(url))
      extract_path = Dir.mktmpdir

      begin
        download(url, zip_path)
        extract(zip_path, extract_path)
        yield(extract_path)
      ensure
        FileUtils.remove_entry(extract_path) if File.exist?(extract_path)
        FileUtils.remove_entry(zip_path) if File.exist?(zip_path)
      end
    end

    def self.download(url, destination)
      if url.start_with?("http", "https")
        URI.open(url) { |remote_file| File.binwrite(destination, remote_file.read) }
      else
        FileUtils.cp(url, destination)
      end
    rescue OpenURI::HTTPError => e
      raise "Failed to download from #{url}: #{e.message}"
    rescue StandardError => e
      raise "Error downloading file: #{e.message}"
    end

    def self.extract(zip_path, destination)
      FileUtils.mkdir_p(destination)
      Zip::File.open(zip_path) do |zip_file|
        zip_file.each do |entry|
          entry_path = File.join(destination, entry.name)
          FileUtils.mkdir_p(File.dirname(entry_path))
          zip_file.extract(entry, entry_path) unless File.exist?(entry_path)
        end
      end
    rescue Zip::Error => e
      raise "Failed to extract zip file: #{e.message}"
    rescue StandardError => e
      raise "Error extracting zip: #{e.message}"
    end
  end
end
