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

class Server
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
        append_to_ssh_config.
        test_ssh_connection.
        update_env.
        install_td_agent.
        restart_processes
  end

  def launch
    params = {
        launch_template: {launch_template_id: @template},
        min_count: 1,
        max_count: 1,
        security_group_ids: [@security_group],
        subnet_id: @subnet
    }

    instance = resource.create_instances(params).first
    @id = instance.id

    wait_until(@id, :instance_running)
    wait_until(@id, :instance_status_ok)

    add_tag(instance, @name)
    @public_ip = Instance.retrieve(instance.id)&.public_ip

    self
  end

  def terminate
    params = {instance_ids: [@id]}
    resource.client.terminate_instances(params)
    wait_until(@id, :instance_terminated)

    self
  end

  def append_to_ssh_config
    puts to_ssh_config
    File.open('./ssh_config', 'a') { |f| f.puts(to_ssh_config) }

    self
  end

  def test_ssh_connection
    cmd = "ssh -q #{@name} exit"
    Util.green(cmd)
    30.times do |n|
      puts "waiting for test_ssh_connection #{@id}"
      if system(cmd, exception: false)
        break
      else
        sleep 5
      end
      raise if n == 29
    end

    self
  end

  def install_td_agent
    [
        'test -f "/usr/sbin/td-agent" || curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent2.sh | sh',
        '/usr/sbin/td-agent-gem list | egrep "fluent-plugin-slack" >/dev/null 2>&1 || sudo /usr/sbin/td-agent-gem install fluent-plugin-slack',
        '/usr/sbin/td-agent-gem list | egrep "fluent-plugin-rewrite-tag-filter.+2\.2\.0" >/dev/null 2>&1 || sudo /usr/sbin/td-agent-gem install fluent-plugin-rewrite-tag-filter -v "2.2.0"',
    ].each { |cmd| run_command(cmd) }

    conf = ERB.new(File.read('./setup/etc/td-agent/td-agent.web.conf.erb')).result_with_hash(
        name: @name,
        webhook_rails: ENV['SLACK_TD_AGENT_RAILS'],
        webhook_puma: ENV['SLACK_TD_AGENT_PUMA'],
        webhook_syslog: ENV['SLACK_TD_AGENT_SYSLOG'],
        webhook_error_log: ENV['SLACK_TD_AGENT_ERROR_LOG'])
    fname = "td-agent.#{Time.now.to_f}.conf"

    File.write(fname, conf)
    system("rsync -auz #{fname} #{@name}:/var/egotter/#{fname}")

    if run_command("diff /var/egotter/#{fname} /etc/td-agent/td-agent.conf >/dev/null 2>&1", exception: false)
      run_command("rm /var/egotter/#{fname}")
    else
      puts conf
      puts fname
      run_command("sudo mv /var/egotter/#{fname} /etc/td-agent/td-agent.conf")
    end
    File.delete(fname)

    self
  end

  def update_env
    contents = ::SecretFile.read('env/web.env.enc')
    fname = "web.env.#{Time.now.to_f}.tmp"
    File.write(fname, contents)
    system("rsync -auz #{fname} #{@name}:/var/egotter/#{fname}")

    if run_command("diff /var/egotter/.env /var/egotter/#{fname} >/dev/null 2>&1", exception: false)
      run_command("rm /var/egotter/#{fname}")
    else
      puts contents
      puts fname
      run_command("mv /var/egotter/#{fname} /var/egotter/.env")
    end
    File.delete(fname)

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

  private

  def resource
    @resource ||= Aws::EC2::Resource.new(region: 'ap-northeast-1')
  end

  def add_tag(instance, value)
    tags = [{key: 'Name', value: value}]
    instance.create_tags(tags: tags)
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

  def run_command(cmd, exception: true)
    raise 'Hostname is empty.' if @name.to_s.empty?
    Util.green("#{@name} #{cmd}")
    system('ssh', @name, "cd /var/egotter && #{cmd}", exception: exception).tap { |r| puts r }
  end

  def to_ssh_config
    <<~"TEXT"
      # #{@id}
      Host #{@name}
        HostName        #{@public_ip}
        IdentityFile    ~/.ssh/egotter.pem
        User            ec2-user
    TEXT
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

    Util.green "Current targets count is #{list_instances.size} (was #{previous_count})"

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

    Util.green "Current targets count is #{list_instances.size} (was #{previous_count})"

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

    server = Server.new(values).start
    target_group.register(server.id)

    if params['rotate']
      instance = target_group.list_instances.sort_by { |i| i.launched_at }.first
      target_group.deregister(instance.id)
      Server.new(id: instance.id).terminate
    end

    %x(git tag deploy-web-#{server.name}-#{Time.now.to_i})
    %x(git push origin --tags)

  elsif params['list']
    state = params['state'].to_s.empty? ? 'healthy' : params['state']
    puts target_group.list_instances(state: state).map(&:name).join(params['delim'] || ' ')
  elsif params['debug']
  end
end
