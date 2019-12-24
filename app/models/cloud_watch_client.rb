require 'aws-sdk-cloudwatch'

class CloudWatchClient
  REGION = 'ap-northeast-1'

  def initialize
    @client = Aws::CloudWatch::Client.new(region: REGION)
  end

  class Metrics
    def initialize
      @client = CloudWatchClient.new
      @metrics = Hash.new { |hash, key| hash[key] = [] }
      @changed = false
    end

    def append(name, value, namespace:, dimensions: nil)
      @metrics[namespace] << {
          metric_name: name,
          dimensions: dimensions,
          timestamp: Time.zone.now,
          value: value,
          unit: 'Count'
      }
      @changed = true

      self
    end

    def update
      if @changed
        @metrics.each do |namespace, metric_data|
          params = {
              namespace: namespace,
              metric_data: metric_data,
          }
          logger.info params.inspect
          @client.instance_variable_get(:@client).put_metric_data(params)
        end
      end
    end

    def logger
      defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    end
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

  def list_dashboards
    @client.list_dashboards.dashboard_entries
  end

  def get_dashboard(name)
    @client.get_dashboard(dashboard_name: name)
  end

  def put_dashboard(name, body)
    @client.put_dashboard(dashboard_name: name, dashboard_body: body.to_json)
  end

  class Dashboard
    def initialize(name)
      @client = CloudWatchClient.new
      @name = name
      @dashboard_body = JSON.parse(@client.get_dashboard(name).dashboard_body)
      @changes = []
    end

    def append_cpu_utilization(instance_id)
      append_instance('CPUUtilization', 'AWS/EC2', ['...', instance_id])
    end

    def append_memory_utilization(instance_id)
      append_instance('MemoryUtilization', 'System/Linux', ['...', instance_id])
    end

    def append_cpu_credit_balance(instance_id)
      append_instance('CPUCreditBalance1', 'AWS/EC2', ['...', instance_id])
    end

    def append_disk_space_utilization(instance_id)
      append_instance('DiskSpaceUtilization1', 'System/Linux', ['...', instance_id, '.', '.'])
    end

    def append_instance(widget_name, namespace, metric)
      @dashboard_body['widgets'].each do |widget|
        if widget['properties']['title'].to_s == widget_name && widget['properties']['metrics'][0][0] == namespace
          widget['properties']['metrics'] << metric
          @changes << widget['properties']['metrics']
          break
        end
      end

      self
    end

    def update
      unless @changes.empty?
        logger.info @changes.inspect
        @client.put_dashboard(@name, @dashboard_body)
      end
    end

    def logger
      defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    end
  end
end
