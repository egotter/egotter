#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'dotenv/load'

if __FILE__ == $0
  # api_v1_users_invalidate_expired_credentials_path
  url = 'https://egotter.com/api/v1/users/invalidate_expired_credentials?key=' + ENV['STATS_API_KEY']
  puts Net::HTTP.post_form(URI.parse(url), {}).body
end
