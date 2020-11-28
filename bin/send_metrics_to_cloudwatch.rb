#!/usr/bin/env ruby

require 'net/http'
require 'uri'

if __FILE__ == $0
  # api_v1_metrics_send_to_cloudwatch_path
  url = 'https://egotter.com/api/v1/metrics/send_to_cloudwatch'
  puts Net::HTTP.post_form(URI.parse(url), {}).body
end
