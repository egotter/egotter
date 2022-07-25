require 'aws-sdk-cloudwatch'

class SendMetricsToCloudWatchWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def unique_in
    55.seconds
  end

  def expire_in
    55.seconds
  end

  def timeout_in
    55.seconds
  end

  # Run every minute
  def perform(type = nil)
    calc_metrics(:send_google_analytics_metrics)
    client.update
  rescue => e
    Airbag.exception e, type: type
  end

  private

  def calc_metrics(type)
    send(type)
  rescue => e
    Airbag.exception e, type: type
  end

  def send_google_analytics_metrics
    namespace = "Google Analytics#{"/#{Rails.env}" unless Rails.env.production?}"
    client = GoogleAnalyticsClient.new

    put_metric_data('rt:activeUsers', client.active_users, namespace: namespace, dimensions: [{name: 'rt:deviceCategory', value: 'TOTAL'}])
    put_metric_data('rt:activeUsers', client.mobile_active_users, namespace: namespace, dimensions: [{name: 'rt:deviceCategory', value: 'MOBILE'}])
    put_metric_data('rt:activeUsers', client.desktop_active_users, namespace: namespace, dimensions: [{name: 'rt:deviceCategory', value: 'DESKTOP'}])
  end

  private

  def client
    @client ||= Metrics.new
  end

  def put_metric_data(*args)
    client.append(*args)
  end

  class Metrics
    def initialize
      @metrics = Hash.new { |hash, key| hash[key] = [] }
      @appended = false
    end

    def append(name, value, namespace:, dimensions: nil)
      @metrics[namespace] << {
          metric_name: name,
          dimensions: dimensions,
          timestamp: Time.zone.now,
          value: value,
          unit: 'Count'
      }
      @appended = true

      self
    end

    def update
      return unless @appended

      client = Aws::CloudWatch::Client.new(region: CloudWatchClient::REGION)

      @metrics.each do |namespace, metric_data|
        Airbag.info "Send #{metric_data.size} metrics to #{namespace}"

        metric_data.each_slice(20).each do |data|
          params = {
              namespace: namespace,
              metric_data: data,
          }
          client.put_metric_data(params)
        rescue => e
          Airbag.exception e, data: data
        end
      end
    end
  end
end
