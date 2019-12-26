require_relative '../app/models/cloud_watch_client'

require_relative '../lib/secret_file'

require_relative './lib/aws'
require_relative './lib/launch'
require_relative './lib/install'
require_relative './lib/uninstall'

module AwsTask
  def build(params)
    if params['launch']
      LaunchTask.build(params)
    elsif params['terminate']
      TerminateTask.build(params)
    elsif params['sync']
      SyncTask.build(params)
    elsif params['list']
      ListTask.build(params)
    end
  end

  module_function :build
end

module LaunchTask
  def build(params)
    role = params['role']

    if role == 'web'
      WebTask.new(params)
    elsif role == 'sidekiq'
      SidekiqTask.new(params)
    else
      raise "Invalid role #{role}"
    end
  end

  module_function :build

  class Task
    attr_reader :kind, :instance

    def initialize
      @kind = :launch
      @instance = nil
      @role = nil
      @launched = nil
      @terminated = nil
    end

    def run
      after_launch if @launched
      after_terminate if @terminated
    end

    private

    def after_launch
      CloudWatchClient::Dashboard.new('egotter-linux-system').
          append_cpu_utilization(@role, @launched.id).
          append_memory_utilization(@role, @launched.id).
          append_cpu_credit_balance(@role, @launched.id).
          append_disk_space_utilization(@role, @launched.id).
          update
    end

    def after_terminate
      CloudWatchClient::Dashboard.new('egotter-linux-system').
          remove_cpu_utilization(@role, @terminated.id).
          remove_memory_utilization(@role, @terminated.id).
          remove_cpu_credit_balance(@role, @terminated.id).
          remove_disk_space_utilization(@role, @terminated.id).
          update
    end

    def append_to_ssh_config(id, host, public_ip)
      text = <<~"TEXT"
        # #{id}
        Host #{host}
          HostName     #{public_ip}
          IdentityFile ~/.ssh/egotter.pem
          User         ec2-user
      TEXT

      puts text
      File.open('./ssh_config', 'a') { |f| f.puts(text) }
    end
  end

  class WebTask < Task
    def initialize(params)
      super()
      @params = params
      @role = params['role']

      target_group_arn = params['target-group'] || ENV['AWS_TARGET_GROUP']
      @target_group = ::Egotter::Aws::TargetGroup.new(target_group_arn)
    end

    def run
      az = @target_group.availability_zone_with_fewest_instances
      params = ::Egotter::Launch::Params.new(@params.merge('availability-zone' => az))
      server = ::Egotter::Launch::Web.new(params).launch
      append_to_ssh_config(server.id, server.host, server.public_ip)
      ::Egotter::Install::Web.new(server.id).install

      @target_group.register(server.id)
      @instance = @launched = server

      if @params['rotate']
        instance = @target_group.oldest_instance
        if instance && @target_group.deregister(instance.id)
          instance.terminate
          @terminated = instance
        end
      end

      super
    end
  end

  class SidekiqTask < Task
    def initialize(params)
      super()
      @params = params
      @role = params['role']
    end

    def run
      az = 'ap-northeast-1b'
      params = ::Egotter::Launch::Params.new(@params.merge('availability-zone' => az))
      server = ::Egotter::Launch::Sidekiq.new(params).launch
      append_to_ssh_config(server.id, server.host, server.public_ip)
      ::Egotter::Install::Sidekiq.new(server.id).install

      @instance = @launched = server

      super
    end
  end
end

module TerminateTask
  def build(params)
    role = params['role']

    if role == 'web'
      WebTask.new(params)
    elsif role == 'sidekiq'
      SidekiqTask.new(params)
    else
      raise "Invalid role #{role}"
    end
  end

  module_function :build

  class Task
    attr_reader :kind, :instance

    def initialize
      @kind = :terminate
      @instance = nil
      @role = nil
      @terminated = nil
    end

    def run
      after_terminate if @terminated
    end

    def after_terminate
      CloudWatchClient::Dashboard.new('egotter-linux-system').
          remove_cpu_utilization(@role, @terminated.id).
          remove_memory_utilization(@role, @terminated.id).
          remove_cpu_credit_balance(@role, @terminated.id).
          remove_disk_space_utilization(@role, @terminated.id).
          update
    end
  end

  class WebTask < Task
    def initialize(params)
      super()
      @role = params['role']

      target_group_arn = params['target-group'] || ENV['AWS_TARGET_GROUP']
      @target_group = ::Egotter::Aws::TargetGroup.new(target_group_arn)
    end

    def run
      instance = @target_group.oldest_instance
      if instance && @target_group.deregister(instance.id)
        instance.terminate
        @instance = @terminated = instance
      end

      super
    end
  end

  class SidekiqTask < Task
    def initialize(params)
      super()
      @params = params
      @role = params['role']
    end

    def run
      instance = ::Egotter::Aws::Instance.retrieve_by(id: @params['instance-id'], name: @params['instance-name'])
      if instance
        ::Egotter::Uninstall::Sidekiq.new(instance.id).uninstall
        instance.terminate
        @instance = @terminated = instance
      end

      super
    end
  end
end

module SyncTask
  def build(params)
    role = params['role']

    if role == 'web'
      WebTask.new(params)
    elsif role == 'sidekiq'
      SidekiqTask.new(params)
    else
      raise "Invalid role #{role}"
    end
  end

  module_function :build

  class Task
    attr_reader :kind, :instance

    def initialize
      @kind = :sync
      @instance = nil
    end
  end

  class WebTask < Task
    def initialize(params)
      @instance_id = params['instance-id']
    end

    def run
      task = ::Egotter::Install::Web.new(@instance_id)
      task.sync
      @instance = task.instance
    end
  end

  class SidekiqTask < Task
    def initialize(params)
      @instance_id = params['instance-id']
    end

    def run
      task = ::Egotter::Install::Sidekiq.new(@instance_id)
      task.sync
      @instance = task.instance
    end
  end
end

module ListTask
  def build(params)
    role = params['role']

    if role == 'web'
      WebTask.new(params)
    else
      raise "Invalid role #{role}"
    end
  end

  module_function :build

  class Task
    attr_reader :kind

    def initialize
      @kind = :list
    end
  end

  class WebTask < Task
    def initialize(params)
      @state = params['state'].to_s.empty? ? 'healthy' : params['state']
      @delim = params['delim'] || ' '

      target_group_arn = params['target-group'] || ENV['AWS_TARGET_GROUP']
      @target_group = ::Egotter::Aws::TargetGroup.new(target_group_arn)
    end

    def run
      puts @target_group.instances(state: @state).map(&:name).join(@delim)
    end
  end
end
