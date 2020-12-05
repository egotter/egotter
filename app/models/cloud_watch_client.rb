require 'aws-sdk-cloudwatch'

class CloudWatchClient
  REGION = 'ap-northeast-1'

  module Logging
    def logger
      if File.basename($0) == 'rake'
        Logger.new(STDOUT)
      elsif defined?(Sidekiq)
        Sidekiq.logger
      elsif defined?(Rails)
        Rails.logger
      else
        Logger.new(STDOUT)
      end
    end
  end

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

  def list_dashboards
    @client.list_dashboards.dashboard_entries
  end

  def get_dashboard(name)
    @client.get_dashboard(dashboard_name: name)
  end

  def put_dashboard(name, body)
    @client.put_dashboard(dashboard_name: name, dashboard_body: body.to_json)
  end

  # TODO Remove later
  class Dashboard
    include Logging

    def initialize(name)
      @client = CloudWatchClient.new
      @name = name
      @dashboard_body = nil
      @changes = []
    end

    def append_cpu_utilization(role, instance_id)
      append_instance("CPUUtilization#{role_suffix(role)}", 'AWS/EC2', ['...', instance_id])
    end

    def append_memory_utilization(role, instance_id)
      append_instance("MemoryUtilization#{role_suffix(role)}", 'System/Linux', ['...', instance_id])
    end

    def append_cpu_credit_balance(role, instance_id)
      append_instance("CPUCreditBalance#{role_suffix(role)}", 'AWS/EC2', ['...', instance_id])
    end

    def append_disk_space_utilization(role, instance_id)
      append_instance("DiskSpaceUtilization#{role_suffix(role)}", 'System/Linux', ['...', instance_id, '.', '.'])
    end

    def remove_cpu_utilization(role, instance_id)
      remove_instance("CPUUtilization#{role_suffix(role)}", 'AWS/EC2', instance_id)
    end

    def remove_memory_utilization(role, instance_id)
      remove_instance("MemoryUtilization#{role_suffix(role)}", 'System/Linux', instance_id)
    end

    def remove_cpu_credit_balance(role, instance_id)
      remove_instance("CPUCreditBalance#{role_suffix(role)}", 'AWS/EC2', instance_id)
    end

    def remove_disk_space_utilization(role, instance_id)
      remove_instance("DiskSpaceUtilization#{role_suffix(role)}", 'System/Linux', instance_id)
    end

    def role_suffix(role)
      if role.start_with?('web')
        '1'
      elsif role.start_with?('sidekiq')
        '2'
      else
        raise "Invalid role #{role}"
      end
    end

    def append_instance(widget_name, namespace, metric)
      dashboard_body['widgets'].each do |widget|
        if widget['properties']['title'].to_s == widget_name && widget['properties']['metrics'][0][0] == namespace
          widget['properties']['metrics'] << metric
          @changes << widget['properties']['metrics']
          break
        end
      end

      self
    end

    def remove_instance(widget_name, namespace, instance_id)
      dashboard_body['widgets'].each do |widget|
        if widget['properties']['title'].to_s == widget_name && widget['properties']['metrics'][0][0] == namespace
          widget['properties']['metrics'].delete_if.with_index { |metric, i| i != 0 && metric.include?(instance_id) }
          @changes << widget['properties']['metrics']
          break
        end
      end

      self
    end

    def dashboard_body
      @dashboard_body ||= JSON.parse(@client.get_dashboard(@name).dashboard_body)
    end

    def update
      unless @changes.empty?
        @changes.each { |change| logger.info change.inspect }
        @client.put_dashboard(@name, @dashboard_body)
      end
    end
  end
end
