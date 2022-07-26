#!/usr/bin/env ruby

require_relative '../deploy/lib/deploy/aws/log_uploader'

def main(name)
  if name.nil? || name.empty?
    puts 'NAME not found'
    return
  end

  LogUploader.new(name).
      add('log/production.log').
      add('log/sidekiq.log').
      add('log/sidekiq_misc.log').
      add('log/airbag.log').
      add('log/cron.log').
      upload
end

if __FILE__ == $0
  main(ARGV[0])
end
