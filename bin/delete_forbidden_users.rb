#!/usr/bin/env ruby

require 'net/http'
require 'uri'

if __FILE__ == $0
  url = 'https://egotter.com/api/v1/forbidden_users/delete'
  puts Net::HTTP.post_form(URI.parse(url), {}).body
end
