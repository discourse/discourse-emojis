# frozen_string_literal: true

require "zip"
require "fileutils"
require "net/http"
require "uri"

module DiscourseEmojis
  class ZipProcessor
    class DownloadError < StandardError
    end
    class ExtractionError < StandardError
    end

    def self.with_extracted_files(url, &block)
      zip_path = File.join(Dir.tmpdir, File.basename(url))
      extract_path = Dir.mktmpdir

      begin
        download(url, zip_path)
        extract(zip_path, extract_path)
        yield(extract_path)
      ensure
        cleanup([extract_path, zip_path])
      end
    end

    private_class_method def self.download(url, destination)
      if remote_url?(url)
        download_remote_file(url, destination)
      else
        FileUtils.cp(url, destination)
      end
    rescue StandardError => e
      raise DownloadError, "Error downloading file: #{e.message}"
    end

    private

    def self.remote_url?(url)
      url.start_with?("http", "https")
    end

    def self.download_remote_file(url, destination)
      uri = URI(url)
      response =
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(Net::HTTP::Get.new(uri)) do |response|
            case response
            when Net::HTTPRedirection
              return download_remote_file(response["location"], destination)
            when Net::HTTPSuccess
              File.binwrite(destination, response.body)
            else
              raise DownloadError, "Failed to download: #{response.code} #{response.message}"
            end
          end
        end
    end

    def self.extract(zip_path, destination)
      FileUtils.mkdir_p(destination)

      Zip::File.open(zip_path) do |zip_file|
        zip_file.each { |entry| extract_entry(entry, destination) }
      end
    rescue Zip::Error => e
      raise ExtractionError, "Failed to extract zip file: #{e.message}"
    rescue StandardError => e
      raise ExtractionError, "Error extracting zip: #{e.message}"
    end

    def self.extract_entry(entry, destination)
      entry_path = File.join(destination, entry.name)
      return if File.exist?(entry_path)

      FileUtils.mkdir_p(File.dirname(entry_path))
      entry.extract(entry_path)
    end

    def self.cleanup(paths)
      paths.each { |path| FileUtils.remove_entry(path) if path && File.exist?(path) }
    end
  end
end
