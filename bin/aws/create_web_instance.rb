#!/usr/bin/env ruby

require 'dotenv/load'

require 'optparse'
require 'aws-sdk-ec2'
require 'aws-sdk-elasticloadbalancingv2'
require 'base64'
require 'erb'

STDOUT.sync = true

class Instance
  attr_reader :id, :name, :public_ip, :availability_zone

  def initialize(instance)
    @id = instance.id
    @name = instance.tags.find { |t| t.key == 'Name' }&.value
    @public_ip = instance.public_ip_address
    @availability_zone = instance.placement.availability_zone
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
  def initialize(template: nil, security_group: nil, subnet: nil, name: nil)
    @template = template
    @security_group = security_group
    @subnet = subnet
    @name = name
    @id = nil
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

    ec2 = Aws::EC2::Resource.new(region: 'ap-northeast-1')
    instance = ec2.create_instances(params).first
    @id = instance.id

    wait_until(@id, :instance_running)
    wait_until(@id, :instance_status_ok)

    add_tag(instance, @name)
    @public_ip = Instance.retrieve(instance.id)&.public_ip

    self
  end

  def id
    @id
  end

  def host
    @name
  end

  def public_ip
    @public_ip
  end

  def append_to_ssh_config
    puts to_ssh_config
    File.open('./ssh_config', 'a') { |f| f.puts(to_ssh_config) }

    self
  end

  def test_ssh_connection
    cmd = "ssh -q #{@name} exit"
    puts "\e[32m#{cmd}\e[0m" # Green
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
    system("rsync -auz .web.env #{@name}:/var/egotter/.env")

    self
  end

  def restart_processes
    [
        'sudo rm -rf /var/tmp/aws-mon/*',
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

  def register_for(target_group)
    alb = Aws::ElasticLoadBalancingV2::Client.new(region: 'ap-northeast-1')
    params = {
        target_group_arn: target_group,
        targets: [{id: @id}]
    }
    puts params.inspect
    alb.register_targets(params)

    begin
      alb.wait_until(:target_in_service, params) do |w|
        w.before_wait do |n, resp|
          puts "waiting for target_in_service #{@id}"
        end
      end
    rescue Aws::Waiters::Errors::WaiterFailed => e
      puts "failed waiting for target_in_service: #{e.message}"
      exit
    end

    self
  end

  private

  def add_tag(instance, value)
    tags = [{key: 'Name', value: value}]
    instance.create_tags(tags: tags)
  end

  def wait_until(id, name)
    ec2 = Aws::EC2::Resource.new(region: 'ap-northeast-1')
    ec2.client.wait_until(name, instance_ids: [id]) do |w|
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
    puts "\e[32m#{@name} #{cmd}\e[0m" # Green
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

  def list_instances
    alb = Aws::ElasticLoadBalancingV2::Client.new(region: 'ap-northeast-1')
    params = {target_group_arn: @arn}
    alb.describe_target_health(params).target_health_descriptions.map do |description|
      Instance.retrieve(description.target.id)
    end
  end
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

if __FILE__ == $0
  params = ARGV.getopts(
      'r:',
      'launch-template:',
      'name-tag:',
      'security-group:',
      'subnet:',
      'target-group:',
      'availability-zone:',
      'create',
      'list',
      'debug',
  )

  target_group = params['target-group'] || ENV['AWS_TARGET_GROUP']

  if params['create']
    az = params['availability-zone'].to_s.empty? ? assign_availability_zone(target_group) : params['availability-zone']
    subnet = az_to_subnet(az)

    values = {
        template: params['launch-template'] || ENV['AWS_LAUNCH_TEMPLATE'],
        security_group: params['security-group'] || ENV['AWS_SECURITY_GROUP'],
        name: params['name-tag'].to_s.empty? ? generate_name : params['name-tag'],
        subnet: subnet || ENV['AWS_SUBNET']
    }
    puts values.inspect

    server = Server.new(values).start
    server.register_for(target_group)

  elsif params['list']
    puts TargetGroup.new(target_group).list_instances.map(&:name).join(' ')
  elsif params['debug']
  end
end
