require 'aws-sdk'

class CloudwatchClient
  REGION = 'ap-northeast-1'

  def initialize
    @cloudwatch = Aws::CloudWatch::Client.new(region: REGION)
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
    @cloudwatch.put_metric_data(values)
  end
end
