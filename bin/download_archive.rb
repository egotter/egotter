#!/usr/bin/env ruby

require 'aws-sdk-s3'
require_relative '../app/lib/s3/archive_data'

def main
  region = ENV['REGION'] || 'ap-northeast-1'
  bucket = ENV['BUCKET']
  key = ENV['KEY']
  out_dir = ENV['OUT_DIR'] || '.'

  s3 = Aws::S3::Resource.new(region: region).bucket(bucket)
  obj = s3.object(key)
  raise "File doesn't exist" unless obj.exists?

  filename = obj.get.metadata['filename']
  raise 'Invalid filename' unless filename.match?(S3::ArchiveData::FILENAME_REGEXP)

  obj.download_file("#{out_dir}/#{filename}")
end

if __FILE__ == $0
  begin
    main
  rescue => e
    puts("#{$0}: #{e.inspect}")
  end
end
