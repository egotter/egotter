module Egotter
  module Server
    module Util
      def test_ssh_connection(host)
        cmd = "ssh -q #{host} exit"
        AwsUtil.green(cmd)
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
        AwsUtil.green("#{host} #{cmd}")
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
        [id, Instance.retrieve(instance.id).public_ip]
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
  end
end