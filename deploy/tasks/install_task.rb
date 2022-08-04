require 'erb'

require_relative '../../app/lib/secret_file'

require_relative '../lib/deploy/aws/instance'
require_relative './util'

module Tasks
  module InstallTask
    module Util
      include ::Tasks::Util

      def exec_command(*args)
        super(@ip_address, *args)
      end

      def rsync(src_path, dst_path)
        cmd = "rsync -auz -e 'ssh -i ~/.ssh/egotter.pem' #{src_path} ec2-user@#{@ip_address}:#{dst_path}"
        logger.info gray("rsync -auz -e 'ssh -i ~/.ssh/egotter.pem'") + ' ' + "#{src_path} ec2-user@#{@ip_address}:#{dst_path}"
        system(cmd, exception: true)
      end

      def diff?(*files)
        !exec_command("sudo colordiff -u #{files[0]} #{files[1]}", exception: false, diff_cmd: true)
      end

      def exists?(file)
        exec_command("sudo test -f #{file}", exception: false, file_cmd: true)
      end

      def copy(src, dst)
        raise 'Cannot specify wildcard characters' if src.include?('*') || dst.include?('*')
        raise 'src not found' unless exists?(src)

        exec_command("sudo touch #{dst}") unless exists?(dst)

        if diff?(dst, src)
          exec_command("sudo cp -f #{src} #{dst}")
        else
          logger.info "Diff not found src=#{src} dst=#{dst}"
        end
      end

      def upload_file(src, dst)
        tmp = File.join('/var/egotter', "#{File.basename(dst)}.#{Time.now.to_f}.#{Process.pid}.tmp")
        rsync(src, tmp)
        copy(tmp, dst)
      ensure
        exec_command("rm #{tmp}") if exists?(tmp)
      end

      def upload_text(text, dst)
        tmp = File.join(Dir.tmpdir, "#{File.basename(dst)}.#{Time.now.to_f}.#{Process.pid}.tmp")
        IO.binwrite(tmp, text)
        upload_file(tmp, dst)
      ensure
        File.delete(tmp) if File.exists?(tmp)
      end

      def upload_env(src)
        text = ::SecretFile.read(src)

        if text.match?(/AWS_NAME_TAG="NONAME"/)
          text.gsub!(/AWS_NAME_TAG="NONAME"/, "AWS_NAME_TAG=\"#{@name}\"")
        end

        upload_text(text, '/var/egotter/.env')
      end
    end

    class Task
      include Util

      def initialize(name, ip_address)
        @name = name
        @ip_address = ip_address
      end

      def backend(cmd, exception: true)
        exec_command(cmd, exception: exception)
      end

      def update_bashrc
        backend("sed -i -e 's/_HOSTNAME_/#{@name}/g' ~/.bashrc")
      end

      def install_td_agent(src)
        options = {
            name: @name,
            slack_td_agent_token: ENV['SLACK_BOT_TOKEN'],
        }
        backend('sudo chmod +r /var/log/messages')
        backend('sudo chmod +rx /var/log/nginx')

        conf = ERB.new(File.read(src)).result_with_hash(options)
        upload_text(conf, '/etc/td-agent/td-agent.conf')
      end

      def pull_latest_code
        backend('git fetch origin >/dev/null')
        backend('git pull origin master >/dev/null')
        backend('bundle config set path ".bundle"')
        backend('bundle config set without "test development"')
        backend('bundle install | grep -v Using')
      end

      def precompile
        backend('RAILS_ENV=production bundle exec rake assets:precompile')
        backend('RAILS_ENV=production bundle exec rake assets:upload')
        backend('RAILS_ENV=production bundle exec rake assets:download')
      end

      def update_crontab
        backend('crontab -r || :')
        backend('sudo crontab -r || :')

        copy('./setup/etc/crontab', '/etc/crontab')
        backend('sudo chown root:root /etc/crontab')
        backend('sudo chmod 644 /etc/crontab')

        copy('./setup/var/spool/cron/ec2-user', '/var/spool/cron/ec2-user')
        backend('sudo chown ec2-user:ec2-user /var/spool/cron/ec2-user')
        backend('sudo chmod 644 /var/spool/cron/ec2-user')
      end

      def update_nginx
        copy('./setup/etc/nginx/nginx.conf', '/etc/nginx/nginx.conf')
      end

      def update_puma
        copy('./setup/etc/init/puma.conf', '/etc/init/puma.conf')
      end

      def update_sidekiq
        copy('./setup/etc/init/sidekiq.conf', '/etc/init/sidekiq.conf')
        copy('./setup/etc/init/sidekiq_misc.conf', '/etc/init/sidekiq_misc.conf')
        copy('./setup/etc/init/_sidekiq.conf', '/etc/init/_sidekiq.conf')
        copy('./setup/etc/init/_sidekiq_misc.conf', '/etc/init/_sidekiq_misc.conf')
      end

      def update_datadog
        backend('sudo mkdir -p /etc/datadog-agent/conf.d/sidekiq.d')
        copy('./setup/etc/datadog-agent/conf.d/sidekiq.d/conf.yaml', '/etc/datadog-agent/conf.d/sidekiq.d/conf.yaml')
      end

      def update_cwagent
        dir = '/opt/aws/amazon-cloudwatch-agent'

        [
            "sudo #{dir}/bin/amazon-cloudwatch-agent-ctl -m ec2 -a stop",
            "sudo rm #{dir}/logs/amazon-cloudwatch-agent.log",
            'wget --quiet https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm',
            'sudo yum localinstall --quiet -y amazon-cloudwatch-agent.rpm',
            'sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/',
        ].each do |cmd|
          backend(cmd)
        end

        copy("./setup#{dir}/etc/amazon-cloudwatch-agent.json", "#{dir}/etc/amazon-cloudwatch-agent.json")

        [
            "sudo rm #{dir}/etc/amazon-cloudwatch-agent.d/default",
            "sudo #{dir}/bin/amazon-cloudwatch-agent-ctl -m ec2 -a start",
            'rm amazon-cloudwatch-agent.rpm',
        ].each do |cmd|
          backend(cmd)
        end
      end

      def update_misc
        [
            'sudo yum install --quiet -y libidn-devel',
            'sudo rm -rf /var/tmp/aws-mon/*',
            'sudo rm -rf /var/egotter/tmp/cache/*',
            'sudo rm -rf /var/egotter/log/*',
        ].each do |cmd|
          backend(cmd)
        end
      end
    end

    class Web < Task
      attr_reader :instance

      def initialize(id)
        @id = id
        @instance = ::Deploy::Aws::Instance.retrieve(id)
        super(@instance.name, @instance.public_ip)
      end

      def sync
        update_misc
        pull_latest_code
        update_bashrc
        update_env
        copy('./setup/root/.irbrc', '/root/.irbrc')
        update_datadog
        update_cwagent
        precompile
        update_crontab
        update_nginx
        update_puma
        install_td_agent('./setup/etc/td-agent/td-agent.web.conf.erb')
      end

      def install
        sync
        restart_processes
      rescue => e
        logger.error red("Terminate #{@id} since #{e.class} is raised")
        ::Deploy::Aws::EC2.new.terminate_instance(@id)
        raise
      end

      def update_env
        upload_env('env/web.env.enc')
      end

      def restart_processes
        [
            'sudo stop datadog-agent',
            'sudo service td-agent restart',
            'sudo service nginx restart',
            'sudo start puma && sleep 10',
            'ab -n 50 -c 2 http://localhost:80/',
        ].each do |cmd|
          backend(cmd)
        end
      end
    end

    class Sidekiq < Task
      attr_reader :instance

      def initialize(id)
        @id = id
        @instance = ::Deploy::Aws::Instance.retrieve(id)
        super(@instance.name, @instance.public_ip)
      end

      def sync
        update_misc
        pull_latest_code
        update_bashrc
        update_env
        copy('./setup/root/.irbrc', '/root/.irbrc')
        update_datadog
        update_cwagent
        update_crontab
        update_sidekiq
        install_td_agent('./setup/etc/td-agent/td-agent.sidekiq.conf.erb')
      end

      def install
        sync
        restart_processes
      rescue => e
        logger.error red("Terminate #{@id} since #{e.class} is raised")
        before_terminate
        ::Deploy::Aws::EC2.new.terminate_instance(@id)
        raise
      end

      def update_env
        upload_env('env/sidekiq.env.enc')
      end

      def restart_processes
        [
            'sudo restart datadog-agent',
            'sudo service td-agent restart',
            'sudo service nginx stop || :',
            'sudo stop puma || :',
            'sudo start sidekiq',
            'sudo start sidekiq_misc',
        ].each do |cmd|
          backend(cmd)
        end
      end

      def before_terminate
        [
            'sudo stop sidekiq || :',
            'sudo stop sidekiq_misc || :',
        ].each do |cmd|
          backend(cmd)
        end
      end
    end

    class Plain < Task
      attr_reader :instance

      def initialize(id)
        @id = id
        @instance = ::Deploy::Aws::Instance.retrieve(id)
        super(@instance.name, @instance.public_ip)
      end

      def sync
        update_misc
        pull_latest_code
        copy('./setup/root/.irbrc', '/root/.irbrc')
        update_datadog
        update_cwagent
        update_crontab
        update_nginx
        update_puma
        update_sidekiq
        install_td_agent('./setup/etc/td-agent/td-agent.web.conf.erb')
      end

      def install
        sync
        stop_processes
      rescue => e
        logger.error red("Terminate #{@id} since #{e.class} is raised")
        ::Deploy::Aws::EC2.new.terminate_instance(@id)
        raise
      end

      def stop_processes
        [
            'sudo restart datadog-agent',
            'sudo service td-agent stop || :',
            'sudo service nginx stop || :',
            'sudo stop puma || :',
            'sudo stop sidekiq || :',
            'sudo stop sidekiq_misc || :',
        ].each do |cmd|
          backend(cmd)
        end
      end
    end
  end
end
