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

      def install_td_agent(host, src)
        fname = "td-agent.#{Time.now.to_f}.conf"

        [
            'test -f "/usr/sbin/td-agent" || curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent2.sh | sh',
            '/usr/sbin/td-agent-gem list | egrep "fluent-plugin-slack" >/dev/null 2>&1 || sudo /usr/sbin/td-agent-gem install fluent-plugin-slack',
            '/usr/sbin/td-agent-gem list | egrep "fluent-plugin-rewrite-tag-filter.+2\.2\.0" >/dev/null 2>&1 || sudo /usr/sbin/td-agent-gem install fluent-plugin-rewrite-tag-filter -v "2.2.0"',
        ].each { |cmd| exec_command(host, cmd) }

        conf = ERB.new(File.read(src)).result_with_hash(
            name: host,
            webhook_rails: ENV['SLACK_TD_AGENT_RAILS'],
            webhook_puma: ENV['SLACK_TD_AGENT_PUMA'],
            webhook_sidekiq: ENV['SLACK_TD_AGENT_SIDEKIQ'],
            webhook_sidekiq_import: ENV['SLACK_TD_AGENT_SIDEKIQ_IMPORT'],
            webhook_sidekiq_misc: ENV['SLACK_TD_AGENT_SIDEKIQ_MISC'],
            webhook_sidekiq_prompt_reports: ENV['SLACK_TD_AGENT_SIDEKIQ_PROMPT_REPORTS'],
            webhook_syslog: ENV['SLACK_TD_AGENT_SYSLOG'],
            webhook_error_log: ENV['SLACK_TD_AGENT_ERROR_LOG'],
        )

        File.write(fname, conf)

        upload_file(host, fname, '/etc/td-agent/td-agent.conf')
      ensure
        File.delete(fname) if File.exists?(fname)
      end

      def upload_file(host, src_path, dst_path)
        tmp_file = "#{File.basename(dst_path)}.#{Process.pid}.tmp"
        tmp_path = File.join('/var/egotter', tmp_file)

        system("rsync -auz #{src_path} #{host}:#{tmp_path}")

        if exec_command(host, "colordiff -u #{dst_path} #{tmp_path}", exception: false)
          exec_command(host, "rm #{tmp_path}")
        else
          puts dst_path
          exec_command(host, "sudo mv #{tmp_path} #{dst_path}")
        end

        self
      end

      def upload_contents(host, contents, dst_path)
        tmp_file = "upload_contents.#{Time.now.to_f}.#{Process.pid}.tmp"
        tmp_path = File.join(Dir.tmpdir, tmp_file)
        IO.binwrite(tmp_path, contents)
        upload_file(host, tmp_path, dst_path)
      ensure
        File.delete(tmp_path) if File.exists?(tmp_path)
      end

      def upload_env(host, src)
        contents = ::SecretFile.read(src)
        upload_contents(host, contents, '/var/egotter/.env')
      end

      def exec_command(host, cmd, dir: '/var/egotter', exception: true)
        raise 'Hostname is empty.' if host.to_s.empty?
        AwsUtil.green("#{host} #{cmd}")
        system('ssh', host, "cd #{dir} && #{cmd}", exception: exception).tap { |r| puts r }
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