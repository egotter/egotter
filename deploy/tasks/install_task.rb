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

      def run_rsync(src_path, dst_path)
        cmd = "rsync -auz -e 'ssh -i ~/.ssh/egotter.pem' #{src_path} ec2-user@#{@ip_address}:#{dst_path}"
        logger.info yellow('localhost') + ' ' + green(cmd)
        system(cmd, exception: true)
      end

      def run_copy(src_path, dst_path)
        if !src_path.include?('*') && !dst_path.include?('*')
          if exec_command("sudo test -f #{dst_path}", exception: false, colored: false)
            diff_src = src_path
          else
            diff_src = '/dev/null'
          end

          unless exec_command("sudo colordiff -u #{dst_path} #{diff_src}", exception: false, colored: false)
            exec_command("sudo cp -f #{src_path} #{dst_path}")
          end
        else
          exec_command("sudo cp -f #{src_path} #{dst_path}")
        end
      end

      def upload_file(src_path, dst_path)
        tmp_file = "#{File.basename(dst_path)}.#{Time.now.to_f}.#{Process.pid}.tmp"
        tmp_path = File.join('/var/egotter', tmp_file)

        run_rsync(src_path, tmp_path)

        if exec_command("sudo test -f #{dst_path}", exception: false, colored: false)
          diff_src = dst_path
        else
          diff_src = '/dev/null'
        end

        if exec_command("sudo colordiff -u #{diff_src} #{tmp_path}", exception: false, colored: false)
          exec_command("rm #{tmp_path}")
        else
          exec_command("sudo mv #{tmp_path} #{dst_path}")
        end

        self
      end

      def upload_text(text, dst_path)
        tmp_file = "#{File.basename(dst_path)}.#{Time.now.to_f}.#{Process.pid}.tmp"
        tmp_path = File.join(Dir.tmpdir, tmp_file)

        IO.binwrite(tmp_path, text)
        upload_file(tmp_path, dst_path)
      ensure
        File.delete(tmp_path) if File.exists?(tmp_path)
      end

      def upload_env(encoded_src_path)
        text = ::SecretFile.read(encoded_src_path)

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
        self
      end

      def install_td_agent(src)
        options = {
            name: @name,
            webhook_rails: ENV['SLACK_TD_AGENT_RAILS'],
            webhook_rails_web: ENV['SLACK_TD_AGENT_RAILS_WEB'],
            webhook_rails_sidekiq: ENV['SLACK_TD_AGENT_RAILS_SIDEKIQ'],
            webhook_puma: ENV['SLACK_TD_AGENT_PUMA'],
            webhook_sidekiq: ENV['SLACK_TD_AGENT_SIDEKIQ'],
            webhook_sidekiq_misc: ENV['SLACK_TD_AGENT_SIDEKIQ_MISC'],
            webhook_syslog: ENV['SLACK_TD_AGENT_SYSLOG'],
            webhook_error_log: ENV['SLACK_TD_AGENT_ERROR_LOG'],
        }
        logger.info "#{__method__} options=#{options}"

        backend('sudo chmod +r /var/log/messages')
        backend('sudo chmod +rx /var/log/nginx')

        conf = ERB.new(File.read(src)).result_with_hash(options)
        upload_text(conf, '/etc/td-agent/td-agent.conf')

        self
      end

      def pull_latest_code
        backend('git fetch origin >/dev/null')
        backend('git pull origin master >/dev/null')
        backend('bundle config set path ".bundle"')
        backend('bundle config set without "test development"')
        backend('bundle install | grep -v Using')
        self
      end

      def precompile
        backend('RAILS_ENV=production bundle exec rake assets:precompile')
        backend('RAILS_ENV=production bundle exec rake assets:upload')
        backend('RAILS_ENV=production bundle exec rake assets:download')
        self
      end

      def update_crontab
        backend('crontab -r || :')
        backend('sudo crontab -r || :')

        upload_file('./setup/etc/crontab', '/etc/crontab')
        backend('sudo chown root:root /etc/crontab')
        backend('sudo chmod 644 /etc/crontab')

        upload_file('./setup/var/spool/cron/ec2-user', '/var/spool/cron/ec2-user')
        backend('sudo chown ec2-user:ec2-user /var/spool/cron/ec2-user')
        backend('sudo chmod 644 /var/spool/cron/ec2-user')

        self
      end

      def update_logrotate
        run_copy('./setup/etc/logrotate.d/nginx', '/etc/logrotate.d/nginx')
        self
      end

      def update_nginx
        run_copy('./setup/etc/nginx/nginx.conf', '/etc/nginx/nginx.conf')
        self
      end

      def update_puma
        run_copy('./setup/etc/init.d/puma', '/etc/init.d/puma')
        run_copy('./setup/etc/init/puma.conf', '/etc/init/puma.conf')
        self
      end

      def update_sidekiq
        run_copy('./setup/etc/init/sidekiq*', '/etc/init')
        run_copy('./setup/etc/init/_sidekiq.conf', '/etc/init')
        run_copy('./setup/etc/init/_sidekiq_misc.conf', '/etc/init')
        self
      end

      def update_datadog(role = nil)
        if role == 'web'
          # Do nothing
        elsif role == 'sidekiq'
          tmp_file = '/var/egotter/datadog.sidekiq.conf.yaml.tmp'
          run_rsync('./setup/etc/datadog-agent/conf.d/sidekiq.d/conf.yaml', tmp_file)
          backend('test -e "/etc/datadog-agent/conf.d/sidekiq.d" || sudo mkdir /etc/datadog-agent/conf.d/sidekiq.d')
          backend("sudo mv #{tmp_file} /etc/datadog-agent/conf.d/sidekiq.d/conf.yaml")
        else
          # Do nothing
        end

        self
      end

      def update_misc
        [
            'sudo yum install -y libidn-devel',
            'sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status',
            'sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a stop',
            'sudo rm -rf /var/tmp/aws-mon/*',
            'sudo rm -rf /var/egotter/tmp/cache/*',
            'sudo rm -rf /var/egotter/log/*',
        ].each do |cmd|
          backend(cmd)
        end
        self
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
        update_misc.
            update_bashrc.
            update_env.
            upload_file('./setup/root/.irbrc', '/root/.irbrc').
            pull_latest_code.
            update_datadog('web').
            precompile.
            update_crontab.
            update_logrotate.
            update_nginx.
            update_puma.
            install_td_agent('./setup/etc/td-agent/td-agent.web.conf.erb')
      end

      def install
        sync.restart_processes
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
            'sudo restart datadog-agent',
            'sudo service td-agent restart',
            'sudo service nginx restart',
            'sudo start puma && sleep 10',
            'ab -n 50 -c 2 http://localhost:80/',
        ].each do |cmd|
          backend(cmd)
        end

        self
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
        update_misc.
            update_bashrc.
            update_env.
            upload_file('./setup/root/.irbrc', '/root/.irbrc').
            pull_latest_code.
            update_datadog('sidekiq').
            update_crontab.
            update_logrotate.
            update_sidekiq.
            install_td_agent('./setup/etc/td-agent/td-agent.sidekiq.conf.erb')
      end

      def install
        sync.restart_processes
      rescue => e
        logger.error red("Terminate #{@id} as #{e.class} is raised")
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

        self
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
        update_misc.
            upload_file('./setup/root/.irbrc', '/root/.irbrc').
            pull_latest_code.
            update_datadog.
            update_crontab.
            update_logrotate.
            update_nginx.
            update_puma.
            update_sidekiq
      end

      def install
        sync.stop_processes
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

        self
      end
    end
  end
end
