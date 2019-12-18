#!/usr/bin/env ruby

require 'optparse'

require 'aws-sdk-ec2'
require 'aws-sdk-elasticloadbalancingv2'
require 'base64'

STDOUT.sync = true

def create_instance(launch_template:, security_group:, name_tag:, subnet:)
  params = {
      launch_template: {launch_template_id: launch_template},
      min_count: 1,
      max_count: 1,
      security_group_ids: [security_group],
      subnet_id: subnet
  }

  ec2 = Aws::EC2::Resource.new(region: 'ap-northeast-1')
  instance = ec2.create_instances(params).first

  begin
    ec2.client.wait_until(:instance_running, instance_ids: [instance.id]) do |w|
      w.before_wait do |n, resp|
        puts "waiting for instance running #{instance.id}"
      end
    end

    ec2.client.wait_until(:instance_status_ok, instance_ids: [instance.id]) do |w|
      w.before_wait do |n, resp|
        puts "waiting for instance status ok #{instance.id}"
      end
    end
  rescue Aws::Waiters::Errors::WaiterFailed => e
    puts "failed waiting for instance status ok: #{e.message}"
    exit
  end

  tags = [{key: 'Name', value: name_tag}]
  instance.create_tags(tags: tags)

  filters = [name: 'instance-id', values: [instance.id]]
  ec2.instances(filters: filters).each do |i|
    instance = i
    break
  end

  instance_id = instance.id
  host = instance.tags.find { |t| t.key == 'Name' }.value
  public_ip = instance.public_ip_address

  ssh_config = <<"TEXT"
# #{instance_id}
Host #{host}
  HostName        #{public_ip}
  IdentityFile    ~/.ssh/egotter.pem
  User            ec2-user
TEXT
  puts ssh_config
  File.open('./ssh_config', 'a') { |f| f.puts(ssh_config) }

  cmd = "ssh -q #{host} exit"
  puts "\e[32m#{cmd}\e[0m" # Green
  10.times do |n|
    if system(cmd, exception: false)
      break
    else
      sleep 5
    end
    raise if n == 9
  end

  system("rsync -auz .web.env #{host}:/var/egotter/.env")

  [
      'sudo rm -rf /var/tmp/aws-mon/*',
      'cd /var/egotter && git pull origin master >/dev/null',
      'cd /var/egotter && RAILS_ENV=production bundle exec rake assets:sync:download',
      'sudo service nginx restart',
      'sudo service puma restart',
  ].each do |cmd|
    puts "\e[32m#{host} #{cmd}\e[0m" # Green
    puts system('ssh', host, cmd, exception: true)
  end

  instance.id
end

def register_instance(instance_id:, target_group:)
  alb = Aws::ElasticLoadBalancingV2::Client.new(region: 'ap-northeast-1')
  params = {
      target_group_arn: target_group,
      targets: [{id: instance_id}]
  }
  alb.register_targets(params)

  begin
    alb.wait_until(:target_in_service, params) do |w|
      w.before_wait do |n, resp|
        puts "waiting for target in service #{instance_id}"
      end
    end
  rescue Aws::Waiters::Errors::WaiterFailed => e
    puts "failed waiting for target in service: #{e.message}"
    exit
  end
end

params = ARGV.getopts('r:', 'launch-template:', 'name-tag:', 'security-group:', 'name-tag:', 'subnet:', 'target-group:')

instance_id = create_instance(
    launch_template: params['launch-template'],
    security_group: params['security-group'],
    name_tag: params['name-tag'],
    subnet: params['subnet']
)

register_instance(
    instance_id: instance_id,
    target_group: params['target-group']
)
