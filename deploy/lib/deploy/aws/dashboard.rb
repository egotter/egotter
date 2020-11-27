require 'aws-sdk-cloudwatch'

class Dashboard

  REGION = 'ap-northeast-1'

  def initialize(name)
    @client = Aws::CloudWatch::Client.new(region: REGION)
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
    @dashboard_body ||= JSON.parse(get_dashboard(@name).dashboard_body)
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

  def update
    if @changes.any?
      @changes.each { |change| logger.info change.inspect }
      put_dashboard(@name, @dashboard_body)
    end
  end

  def logger
    Logger.new(STDOUT)
  end
end
