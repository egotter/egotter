require 'aws-sdk-cloudwatch'

class CloudWatchClient
  REGION = 'ap-northeast-1'
  DB_INSTANCE_ID = ENV['DB_INSTANCE_ID']

  def initialize
    @client = Aws::CloudWatch::Client.new(region: REGION, retry_limit: 4, http_open_timeout: 3, http_read_timeout: 3)
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

  def get_metric_statistics(metric_name, namespace:, dimensions:)
    @client.get_metric_statistics(
        namespace: namespace,
        metric_name: metric_name,
        dimensions: dimensions,
        start_time: 5.minutes.ago.iso8601,
        end_time: Time.zone.now.utc.iso8601,
        period: 300,
        statistics: ['Average'],
    )
  end

  def get_active_users(category = 'TOTAL')
    category = 'TOTAL' unless %w(TOTAL MOBILE DESKTOP).include?(category)
    dimensions = [
        {
            name: 'rt:deviceCategory',
            value: category,
        },
    ]
    resp = get_metric_statistics('rt:activeUsers', namespace: 'Google Analytics', dimensions: dimensions)
    resp.datapoints[0].average
  rescue => e
    -1
  end

  def get_rds_burst_balance
    dimensions = [
        {
            name: 'DBInstanceIdentifier',
            value: DB_INSTANCE_ID,
        },
    ]
    resp = get_metric_statistics('BurstBalance', namespace: 'AWS/RDS', dimensions: dimensions)
    resp.datapoints[0].average
  rescue => e
    Airbag.warn "#{__method__}: #{e.inspect}"
    -1
  end

  def list_dashboards
    @client.list_dashboards.dashboard_entries
  end

  def get_dashboard(name)
    @client.get_dashboard(dashboard_name: name)
  end

  def put_dashboard(name, body)
    @client.put_dashboard(dashboard_name: name, dashboard_body: body.to_json)
  end
end
