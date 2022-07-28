#!/usr/bin/env ruby

require 'dotenv/load'
require 'aws-sdk-cloudwatch'

require_relative '../app/lib/google_analytics_client'

class Metrics
  def initialize
    @metrics = Hash.new { |hash, key| hash[key] = [] }
  end

  def namespace(value)
    @namespace = value
    self
  end

  def name(value)
    @name = value
    self
  end

  def append(value, dimensions)
    @metrics[@namespace] << {
        metric_name: @name,
        dimensions: dimensions,
        timestamp: Time.now,
        value: value,
        unit: 'Count'
    }
    self
  end

  def upload
    client = Aws::CloudWatch::Client.new(region: 'ap-northeast-1')

    @metrics.each do |namespace, metric_data|
      metric_data.each_slice(20).each do |data|
        client.put_metric_data(namespace: namespace, metric_data: data)
      end
    end
  end
end

def main
  ga = GoogleAnalyticsClient.new

  Metrics.new.namespace('Google Analytics').name('rt:activeUsers').
      append(ga.active_users, [{name: 'rt:deviceCategory', value: 'TOTAL'}]).
      append(ga.mobile_active_users, [{name: 'rt:deviceCategory', value: 'MOBILE'}]).
      append(ga.desktop_active_users, [{name: 'rt:deviceCategory', value: 'DESKTOP'}]).
      upload
end

if __FILE__ == $0
  main
end
