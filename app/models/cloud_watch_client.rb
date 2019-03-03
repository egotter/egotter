require 'aws-sdk-cloudwatch'

class CloudWatchClient
  REGION = 'ap-northeast-1'

  def initialize
    @client = Aws::CloudWatch::Client.new(region: REGION)
  end

  def put_metric_data(metric_name, value, namespace:, dimensions: nil)
    values = {
      namespace: namespace,
      metric_data: [
        {
          metric_name: metric_name,
          dimensions: dimensions,
          timestamp: Time.zone.now,
          value: value,
          unit: 'Count'
        }
      ]
    }
    @client.put_metric_data(values)
  end
end
