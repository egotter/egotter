#!/usr/bin/env ruby

require 'net/http'
require 'uri'

if __FILE__ == $0
  # api_v1_metrics_update_rds_burst_balance_path
  url = 'https://egotter.com/api/v1/metrics/update_rds_burst_balance'
  puts Net::HTTP.post_form(URI.parse(url), {}).body
end
