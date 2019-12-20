#!/usr/bin/env ruby

require 'dotenv/load'

require 'optparse'
require 'aws-sdk-ec2'
require 'aws-sdk-elasticloadbalancingv2'
require 'base64'
require 'erb'

require_relative '../../lib/secret_file.rb'

STDOUT.sync = true

class Instance
  attr_reader :id, :name, :public_ip, :availability_zone, :launched_at

  def initialize(instance)
    @id = instance.id
    @name = instance.tags.find { |t| t.key == 'Name' }&.value
    @public_ip = instance.public_ip_address
    @availability_zone = instance.placement.availability_zone
    @launched_at = instance.launch_time
  end

  class << self
    def retrieve(id)
      instance = nil
      filters = [name: 'instance-id', values: [id]]
      ec2 = Aws::EC2::Resource.new(region: 'ap-northeast-1')
      ec2.instances(filters: filters).each do |i|
        instance = i
        break
      end
      instance ? new(instance) : nil
    end
  end
end

module Server
  module Util
    def test_ssh_connection(host)
      cmd = "ssh -q #{host} exit"
      ::Util.green(cmd)
      30.times do |n|
        puts "waiting for test_ssh_connection #{host}"
        if system(cmd, exception: false)
          break
        else
          sleep 5
        end
        raise if n == 29
      end

      self
    end

    def append_to_ssh_config(id, host, public_ip)
      text = to_ssh_config(id, host, public_ip)
      puts text
      File.open('./ssh_config', 'a') { |f| f.puts(text) }

      self
    end

    def to_ssh_config(id, host, public_ip)
      <<~"TEXT"
        # #{id}
        Host #{host}
          HostName        #{public_ip}
          IdentityFile    ~/.ssh/egotter.pem
          User            ec2-user
      TEXT
    end

    def install_td_agent(host)
      fname = "td-agent.#{Time.now.to_f}.conf"

      [
          'test -f "/usr/sbin/td-agent" || curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent2.sh | sh',
          '/usr/sbin/td-agent-gem list | egrep "fluent-plugin-slack" >/dev/null 2>&1 || sudo /usr/sbin/td-agent-gem install fluent-plugin-slack',
          '/usr/sbin/td-agent-gem list | egrep "fluent-plugin-rewrite-tag-filter.+2\.2\.0" >/dev/null 2>&1 || sudo /usr/sbin/td-agent-gem install fluent-plugin-rewrite-tag-filter -v "2.2.0"',
      ].each { |cmd| exec_command(host, cmd) }

      conf = ERB.new(File.read('./setup/etc/td-agent/td-agent.web.conf.erb')).result_with_hash(
          name: host,
          webhook_rails: ENV['SLACK_TD_AGENT_RAILS'],
          webhook_puma: ENV['SLACK_TD_AGENT_PUMA'],
          webhook_syslog: ENV['SLACK_TD_AGENT_SYSLOG'],
          webhook_error_log: ENV['SLACK_TD_AGENT_ERROR_LOG'])

      File.write(fname, conf)
      system("rsync -auz #{fname} #{host}:/var/egotter/#{fname}")

      if exec_command(host, "colordiff -u /etc/td-agent/td-agent.conf /var/egotter/#{fname}", exception: false)
        exec_command(host, "rm /var/egotter/#{fname}")
      else
        puts fname
        exec_command(host, "sudo mv /var/egotter/#{fname} /etc/td-agent/td-agent.conf")
      end

      self
    ensure
      File.delete(fname) if File.exists?(fname)
    end

    def update_env(host, src)
      fname = ".env.#{Time.now.to_f}.tmp"
      contents = ::SecretFile.read(src)
      File.write(fname, contents)
      system("rsync -auz #{fname} #{host}:/var/egotter/#{fname}")

      if exec_command(host, "colordiff -u /var/egotter/.env /var/egotter/#{fname}", exception: false)
        exec_command(host, "rm /var/egotter/#{fname}")
      else
        puts fname
        exec_command(host, "mv /var/egotter/#{fname} /var/egotter/.env")
      end

      self
    ensure
      File.delete(fname) if File.exists?(fname)
    end

    def exec_command(host, cmd, exception: true)
      raise 'Hostname is empty.' if host.to_s.empty?
      ::Util.green("#{host} #{cmd}")
      system('ssh', host, "cd /var/egotter && #{cmd}", exception: exception).tap { |r| puts r }
    end

    def launch_instance(template:, security_group:, subnet:, name:)
      params = {
          launch_template: {launch_template_id: template},
          min_count: 1,
          max_count: 1,
          security_group_ids: [security_group],
          subnet_id: subnet
      }

      instance = resource.create_instances(params).first
      id = instance.id

      wait_until(id, :instance_running)
      wait_until(id, :instance_status_ok)

      add_tag(instance, name)
      [id, ::Instance.retrieve(instance.id).public_ip]
    end

    def add_tag(instance, name)
      tags = [{key: 'Name', value: name}]
      instance.create_tags(tags: tags)
    end

    def resource
      @resource ||= Aws::EC2::Resource.new(region: 'ap-northeast-1')
    end

    def wait_until(id, name)
      resource.client.wait_until(name, instance_ids: [id]) do |w|
        w.before_wait do |n, resp|
          puts "waiting for #{name} #{id}"
        end
      end
    rescue Aws::Waiters::Errors::WaiterFailed => e
      puts "failed waiting for #{name}: #{e.message}"
      exit
    end

    def terminate_instance(id)
      params = {instance_ids: [id]}
      resource.client.terminate_instances(params)
      wait_until(id, :instance_terminated)

      self
    end
  end

  class Web
    include Util

    attr_reader :id, :name, :public_id

    def initialize(template: nil, security_group: nil, subnet: nil, name: nil, id: nil)
      @template = template
      @security_group = security_group
      @subnet = subnet
      @name = name
      @id = id
      @public_ip = nil
    end

    def start
      launch.
          append_to_ssh_config(@id, @name, @public_ip).
          test_ssh_connection(@name).
          update_env(@name, 'env/web.env.enc').
          install_td_agent(@name).
          restart_processes
    rescue => e
      terminate if @id
      raise
    end

    def launch
      @id, @public_ip = launch_instance(template: @template, security_group: @security_group, subnet: @subnet, name: @name)

      self
    end

    def restart_processes
      [
          'sudo rm -rf /var/tmp/aws-mon/*',
          'sudo rm -rf /var/egotter/tmp/cache/*',
          'git pull origin master >/dev/null',
          'bundle check || bundle install --quiet --path .bundle --without test development',
          'RAILS_ENV=production bundle exec rake assets:precompile',
          'RAILS_ENV=production bundle exec rake assets:sync:download',
          'sudo service td-agent restart',
          'sudo service nginx restart',
          'sudo service puma restart',
      ].each do |cmd|
        run_command(cmd)
      end

      self
    end

    def terminate
      terminate_instance(@id)
    end

    def run_command(cmd, exception: true)
      exec_command(@name, cmd, exception: exception)
    end
  end
end

class TargetGroup
  def initialize(arn)
    @arn = arn
  end

  def register(instance_id)
    previous_count = list_instances.size

    params = {
        target_group_arn: @arn,
        targets: [{id: instance_id}]
    }
    puts params.inspect
    client.register_targets(params)
    wait_until(:target_in_service, params)

    ::Util.green "Current targets count is #{list_instances.size} (was #{previous_count})"

    self
  end

  def deregister(instance_id)
    previous_count = list_instances.size

    params = {
        target_group_arn: @arn,
        targets: [{id: instance_id}]
    }
    puts params.inspect
    client.deregister_targets(params)
    wait_until(:target_deregistered, params)

    ::Util.green "Current targets count is #{list_instances.size} (was #{previous_count})"

    self
  end

  def list_instances(state: 'healthy')
    params = {target_group_arn: @arn}

    client.describe_target_health(params).
        target_health_descriptions.
        select { |d| d.target_health.state == state }.map do |description|
      Instance.retrieve(description.target.id)
    end
  end

  private

  def wait_until(name, params)
    instance_id = params[:targets][0][:id]

    client.wait_until(name, params) do |w|
      w.before_wait do |n, resp|
        puts "waiting for #{name} #{instance_id}"
      end
    end
  rescue Aws::Waiters::Errors::WaiterFailed => e
    puts "failed waiting for #{name}: #{e.message}"
    exit
  end

  def client
    @client ||= Aws::ElasticLoadBalancingV2::Client.new(region: 'ap-northeast-1')
  end
end

module Util
  module_function

  def green(str)
    puts "\e[32m#{str}\e[0m"
  end

  def generate_name
    "egotter_web#{Time.now.strftime('%m%d%H%M')}"
  end

  def az_to_subnet(az)
    case az
    when 'ap-northeast-1b' then ENV['AWS_SUBNET_1B']
    when 'ap-northeast-1c' then ENV['AWS_SUBNET_1C']
    when 'ap-northeast-1d' then ENV['AWS_SUBNET_1D']
    end
  end

  def assign_availability_zone(target_group)
    count = {
        'ap-northeast-1b' => 0,
        'ap-northeast-1c' => 0,
        'ap-northeast-1d' => 0,
    }
    TargetGroup.new(target_group).list_instances.each { |i| count[i.availability_zone] += 1 }
    count.sort_by { |k, v| v }[0][0]
  end
end

if __FILE__ == $0
  params = ARGV.getopts(
      'h:',
      'launch-template:',
      'name-tag:',
      'security-group:',
      'subnet:',
      'target-group:',
      'availability-zone:',
      'delim:',
      'state:',
      'rotate',
      'create',
      'list',
      'debug',
  )

  target_group_arn = params['target-group'] || ENV['AWS_TARGET_GROUP']
  target_group = TargetGroup.new(target_group_arn)

  if params['create']
    az = params['availability-zone'].to_s.empty? ? Util.assign_availability_zone(target_group_arn) : params['availability-zone']
    subnet = Util.az_to_subnet(az)

    values = {
        template: params['launch-template'] || ENV['AWS_LAUNCH_TEMPLATE'],
        security_group: params['security-group'] || ENV['AWS_SECURITY_GROUP'],
        name: params['name-tag'].to_s.empty? ? Util.generate_name : params['name-tag'],
        subnet: subnet || ENV['AWS_SUBNET']
    }
    puts values.inspect

    server = Server::Web.new(values).start
    target_group.register(server.id)

    if params['rotate']
      instance = target_group.list_instances.sort_by { |i| i.launched_at }.first
      target_group.deregister(instance.id)
      Server::Web.new(id: instance.id).terminate
    end

    %x(git tag deploy-web-#{server.name}-#{Time.now.to_i})
    %x(git push origin --tags)

  elsif params['list']
    state = params['state'].to_s.empty? ? 'healthy' : params['state']
    puts target_group.list_instances(state: state).map(&:name).join(params['delim'] || ' ')
  elsif params['debug']
  end
end
