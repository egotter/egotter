#!/usr/bin/env ruby

require 'net/http'
require 'uri'

if __FILE__ == $0
  # api_v1_bots_invalidate_expired_credentials_path
  url = 'https://egotter.com/api/v1/bots/invalidate_expired_credentials'
  puts Net::HTTP.post_form(URI.parse(url), {}).body
end
