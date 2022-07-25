#!/usr/bin/env ruby

require 'dotenv/load'
require 'aws-sdk-cloudwatch'

require_relative '../app/lib/google_analytics_client'

class Metrics
  def initialize
    @metrics = Hash.new { |hash, key| hash[key] = [] }
  end

  def append(name, value, namespace:, dimensions: nil)
    @metrics[namespace] << {
        metric_name: name,
        dimensions: dimensions,
        timestamp: Time.now,
        value: value,
        unit: 'Count'
    }
  end

  def upload
    client = Aws::CloudWatch::Client.new(region: 'ap-northeast-1')

    @metrics.each do |namespace, metric_data|
      puts "send_metrics_to_cloudwatch.rb: Send #{metric_data.size} metrics to #{namespace}"

      metric_data.each_slice(20).each do |data|
        params = {
            namespace: namespace,
            metric_data: data,
        }
        client.put_metric_data(params)
      rescue => e
        puts "send_metrics_to_cloudwatch.rb: #{e.inspect} data=#{data.inspect}"
      end
    end
  end
end

def main
  namespace = 'Google Analytics'
  ga = GoogleAnalyticsClient.new

  metrics = Metrics.new
  metrics.append('rt:activeUsers', ga.active_users, namespace: namespace, dimensions: [{name: 'rt:deviceCategory', value: 'TOTAL'}])
  metrics.append('rt:activeUsers', ga.mobile_active_users, namespace: namespace, dimensions: [{name: 'rt:deviceCategory', value: 'MOBILE'}])
  metrics.append('rt:activeUsers', ga.desktop_active_users, namespace: namespace, dimensions: [{name: 'rt:deviceCategory', value: 'DESKTOP'}])
  metrics.upload
end

if __FILE__ == $0
  # api_v1_metrics_send_to_cloudwatch_path
  # url = 'https://egotter.com/api/v1/metrics/send_to_cloudwatch'
  # puts Net::HTTP.post_form(URI.parse(url), {}).body
  main
end
