require 'erb'

require_relative '../../lib/secret_file'

require_relative '../lib/deploy_ruby/aws/instance'
require_relative './util'

module Tasks
  module InstallTask
    module Util
      include ::Tasks::Util

      def run_rsync(src_path, dst_path)
        cmd = "rsync -auz -e 'ssh -i ~/.ssh/egotter.pem' #{src_path} ec2-user@#{@ip_address}:#{dst_path}"
        logger.info yellow('localhost') + ' ' + green(cmd)
        system(cmd, exception: true)
      end

      def run_copy(src_path, dst_path)
        if !src_path.include?('*') && !dst_path.include?('*')
          if exec_command("sudo test -f #{dst_path}", exception: false, colored: false)
            diff_src = dst_path
          else
            diff_src = '/dev/null'
          end

          unless exec_command("sudo colordiff -u #{diff_src} #{dst_path}", exception: false, colored: false)
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

      def exec_command(cmd, dir: '/var/egotter', exception: true, colored: true)
        if @ip_address.to_s.empty?
          logger.error red("ip_address is empty cmd=#{cmd}")
          exit
        end

        cmd = "cd #{dir} && #{cmd}"
        ssh_cmd = "ssh -i ~/.ssh/egotter.pem ec2-user@#{@ip_address}"

        if colored
          logger.info cyan(ssh_cmd) + ' ' + green(%Q("#{cmd}"))
        else
          logger.info ssh_cmd + ' ' + %Q("#{cmd}")
        end

        start = Time.now
        out, err, status = Open3.capture3(%Q(#{ssh_cmd} "#{cmd}"))
        elapsed = Time.now - start
        out = out.to_s.chomp
        err = err.to_s.chomp

        logger.info out unless out.empty?

        if status.exitstatus == 0
          logger.info blue("success elapsed=#{sprintf("%.3f sec", elapsed)}\n")
        else
          if exception
            logger.error red(err) unless err.empty?
            logger.error red("fail(exit) elapsed=#{sprintf("%.3f sec", elapsed)}\n")
            exit
          else
            logger.info err unless err.empty?
            logger.error red("fail(continue) elapsed=#{sprintf("%.3f sec", elapsed)}\n")
          end
        end

        status.exitstatus == 0
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

      def install_td_agent(src)
        options = {
            name: @name,
            webhook_rails: ENV['SLACK_TD_AGENT_RAILS'],
            webhook_rails_web: ENV['SLACK_TD_AGENT_RAILS_WEB'],
            webhook_rails_sidekiq: ENV['SLACK_TD_AGENT_RAILS_SIDEKIQ'],
            webhook_puma: ENV['SLACK_TD_AGENT_PUMA'],
            webhook_sidekiq: ENV['SLACK_TD_AGENT_SIDEKIQ'],
            webhook_sidekiq_import: ENV['SLACK_TD_AGENT_SIDEKIQ_IMPORT'],
            webhook_sidekiq_misc: ENV['SLACK_TD_AGENT_SIDEKIQ_MISC'],
            webhook_sidekiq_prompt_reports: ENV['SLACK_TD_AGENT_SIDEKIQ_PROMPT_REPORTS'],
            webhook_syslog: ENV['SLACK_TD_AGENT_SYSLOG'],
            webhook_error_log: ENV['SLACK_TD_AGENT_ERROR_LOG'],
        }
        logger.info "#{__method__} options=#{options}"

        conf = ERB.new(File.read(src)).result_with_hash(options)
        upload_text(conf, '/etc/td-agent/td-agent.conf')

        self
      end

      def pull_latest_code
        backend('git fetch origin >/dev/null')
        backend('git pull origin master >/dev/null')
        backend('bundle install --path .bundle --without test development | grep -v Using')
        self
      end

      def precompile
        backend('RAILS_ENV=production bundle exec rake assets:precompile')
        backend('RAILS_ENV=production bundle exec rake assets:sync:download')
        self
      end

      def update_egotter
        run_copy('./setup/etc/init.d/egotter', '/etc/init.d/egotter')
        self
      end

      def update_crontab
        backend('crontab -r || :')
        backend('sudo crontab -r || :')
        upload_file('./setup/etc/crontab', '/etc/crontab')
        backend('sudo chown root:root /etc/crontab')
        self
      end

      def update_nginx
        run_copy('./setup/etc/nginx/nginx.conf', '/etc/nginx/nginx.conf')
        self
      end

      def update_puma
        run_copy('./setup/etc/init.d/puma', '/etc/init.d/puma')
        self
      end

      def update_sidekiq
        run_copy('./setup/etc/init.d/sidekiq*', '/etc/init.d')
        run_copy('./setup/etc/init/sidekiq*', '/etc/init')
        run_copy('./setup/etc/init.d/patient_sidekiqctl.rb', '/etc/init.d/patient_sidekiqctl.rb')
        self
      end

      def update_datadog
        tmp_file = '/var/egotter/datadog.sidekiq.conf.yaml.tmp'
        run_rsync('./setup/etc/datadog-agent/conf.d/sidekiq.d/conf.yaml', tmp_file)
        backend('test -e "/etc/datadog-agent/conf.d/sidekiq.d" || sudo mkdir /etc/datadog-agent/conf.d/sidekiq.d')
        backend("sudo mv #{tmp_file} /etc/datadog-agent/conf.d/sidekiq.d/conf.yaml")
        self
      end
    end

    class Web < Task
      attr_reader :instance

      def initialize(id)
        @id = id
        @instance = ::DeployRuby::Aws::Instance.retrieve(id)
        super(@instance.name, @instance.public_ip)
      end

      def sync
        update_misc.
            update_env.
            upload_file('./setup/root/.irbrc', '/root/.irbrc').
            pull_latest_code.
            precompile.
            update_egotter.
            update_crontab.
            update_nginx.
            update_puma.
            install_td_agent('./setup/etc/td-agent/td-agent.web.conf.erb')
      end

      def install
        sync.restart_processes
      rescue => e
        logger.error red("Terminate #{@id} since #{e.class} is raised")
        ::DeployRuby::Aws::EC2.new.terminate_instance(@id)
        raise
      end

      def update_env
        upload_env('env/web.env.enc')
      end

      def update_misc
        [
            'sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a stop',
            'sudo rm -rf /var/tmp/aws-mon/*',
            'sudo rm -rf /var/egotter/tmp/cache/*',
            'sudo rm -rf /var/egotter/log/*',
            "sed -i -e 's/web3/#{@name}/g' ~/.bashrc",
        ].each do |cmd|
          backend(cmd)
        end

        self
      end

      def restart_processes
        [
            'sudo service td-agent restart',
            'sudo service nginx restart',
            'sudo service puma restart',
            'sudo restart datadog-agent',
            'ab -n 500 -c 10 http://localhost:80/',
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
        @instance = ::DeployRuby::Aws::Instance.retrieve(id)
        super(@instance.name, @instance.public_ip)
      end

      def sync
        update_misc.
            update_env.
            upload_file('./setup/root/.irbrc', '/root/.irbrc').
            pull_latest_code.
            update_datadog.
            update_egotter.
            update_crontab.
            update_sidekiq.
            install_td_agent('./setup/etc/td-agent/td-agent.sidekiq.conf.erb')
      end

      def install
        sync.restart_processes
      rescue => e
        logger.error red("Terminate #{@id} as #{e.class} is raised")
        before_terminate
        ::DeployRuby::Aws::EC2.new.terminate_instance(@id)
        raise
      end

      def update_env
        upload_env('env/sidekiq.env.enc')
      end

      def update_misc
        [
            'sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a stop',
            'sudo rm -rf /var/tmp/aws-mon/*',
            'sudo rm -rf /var/egotter/tmp/cache/*',
            'sudo rm -rf /var/egotter/log/*',
            "sed -i -e 's/web3/#{@name}/g' ~/.bashrc",
        ].each do |cmd|
          backend(cmd)
        end

        self
      end

      def restart_processes
        [
            'sudo service td-agent restart',
            'sudo service nginx stop || :',
            'sudo service puma stop || :',
            'sudo start sidekiq',
            'sudo start sidekiq_misc',
            'sudo stop sidekiq_prompt_reports_workers',
            'sudo restart datadog-agent',
        ].each do |cmd|
          backend(cmd)
        end

        self
      end

      def before_terminate
        [
            'sudo stop sidekiq || :',
            'sudo stop sidekiq_misc || :',
            'sudo stop sidekiq_prompt_reports_workers || :',
        ].each do |cmd|
          backend(cmd)
        end
      end
    end

    class SidekiqPromptReports < Sidekiq
      attr_reader :instance

      def update_env
        upload_env('env/sidekiq.env.enc')
      end

      def restart_processes
        [
            'sudo service td-agent restart',
            'sudo service nginx stop || :',
            'sudo service puma stop || :',
            'sudo stop sidekiq_misc || :',
            'sudo start sidekiq_workers || :',
            'sudo start sidekiq_prompt_reports_workers',
            'sudo restart datadog-agent',
        ].each do |cmd|
          backend(cmd)
        end

        self
      end
    end

    class Plain < Task
      attr_reader :instance

      def initialize(id)
        @id = id
        @instance = ::DeployRuby::Aws::Instance.retrieve(id)
        super(@instance.name, @instance.public_ip)
      end

      def sync
        update_misc.
            upload_file('./setup/root/.irbrc', '/root/.irbrc').
            pull_latest_code.
            update_egotter.
            update_crontab.
            update_nginx.
            update_puma.
            update_sidekiq
      end

      def install
        sync.stop_processes
      rescue => e
        logger.error red("Terminate #{@id} since #{e.class} is raised")
        ::DeployRuby::Aws::EC2.new.terminate_instance(@id)
        raise
      end

      def update_misc
        [
            'sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a stop',
            'sudo rm -rf /var/tmp/aws-mon/*',
            'sudo rm -rf /var/egotter/tmp/cache/*',
            'sudo rm -rf /var/egotter/log/*',
        ].each do |cmd|
          backend(cmd)
        end

        self
      end

      def stop_processes
        [
            'sudo service td-agent stop || :',
            'sudo service nginx stop || :',
            'sudo service puma stop || :',
            'sudo restart datadog-agent',
            'sudo stop sidekiq || :',
            'sudo stop sidekiq_misc || :',
            'sudo stop sidekiq_prompt_reports_workers || :',
        ].each do |cmd|
          backend(cmd)
        end

        self
      end
    end
  end
end