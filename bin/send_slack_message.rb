#!/usr/bin/env ruby

require 'dotenv/load'
require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_BOT_TOKEN']
end

def main(channel, message)
  if channel.nil? || channel.empty?
    puts "#{$0}: CHANNEL not found"
    return
  end

  if message.nil? || message.empty?
    puts "#{$0}: MESSAGE not found"
    return
  end

  Slack::Web::Client.new.chat_postMessage({channel: channel, text: message})
end

if __FILE__ == $0
  main(ARGV[0], ARGV[1])
end

