require 'erb'

require_relative '../../lib/secret_file'

require_relative '../lib/deploy_ruby/aws/instance'

module Tasks
  module InstallTask
    module Util
      def logger
        DeployRuby.logger
      end

      def red(str)
        "\e[31m#{str}\e[0m"
      end

      def green(str)
        "\e[32m#{str}\e[0m"
      end

      def blue(str)
        "\e[34m#{str}\e[0m"
      end

      def cyan(str)
        "\e[36m#{str}\e[0m"
      end

      def yellow(str)
        "\e[33m#{str}\e[0m"
      end

      def upload_file(host, src_path, dst_path)
        tmp_file = "#{File.basename(dst_path)}.#{Process.pid}.tmp"
        tmp_path = File.join('/var/egotter', tmp_file)

        frontend("rsync -auz #{src_path} #{host}:#{tmp_path}")

        diff_src =
            if exec_command(host, "sudo test -f #{dst_path}", exception: false)
              dst_path
            else
              '/dev/null'
            end

        if exec_command(host, "sudo colordiff -u #{diff_src} #{tmp_path}", exception: false)
          exec_command(host, "rm #{tmp_path}")
        else
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

        if contents.match?(/AWS_NAME_TAG="NONAME"/)
          contents.gsub!(/AWS_NAME_TAG="NONAME"/, "AWS_NAME_TAG=\"#{host}\"")
        end

        upload_contents(host, contents, '/var/egotter/.env')
      end

      def frontend(cmd, exception: true)
        logger.info yellow("localhost #{cmd}")
        system(cmd, exception: exception)
      end

      def exec_command(host, cmd, dir: '/var/egotter', exception: true)
        if host.to_s.empty?
          logger.error red('Hostname is empty.')
          exit
        end

        cmd = "cd #{dir} && #{cmd}"
        logger.info cyan(%Q(ssh #{host})) + ' ' + green(%Q("#{cmd}"))

        out, err, status = Open3.capture3(%Q(ssh #{host} "#{cmd}"))
        if status.exitstatus == 0
          logger.info out
          logger.info blue("true(success)")
        else
          if exception
            logger.info out
            logger.error red(err)
            logger.error red("false(exit)")
            exit
          else
            logger.info out
            logger.info err
          end
        end

        status.exitstatus == 0
      end
    end

    class Task
      include Util

      def initialize(name)
        @name = name
      end

      def backend(cmd, exception: true)
        exec_command(@name, cmd, exception: exception)
      end

      def install_td_agent(host, src)
        [
            'test -f "/usr/sbin/td-agent" || curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent2.sh | sh',
            '/usr/sbin/td-agent-gem list | egrep "fluent-plugin-slack" >/dev/null 2>&1 || sudo /usr/sbin/td-agent-gem install fluent-plugin-slack',
            '/usr/sbin/td-agent-gem list | egrep "fluent-plugin-rewrite-tag-filter.+2\.2\.0" >/dev/null 2>&1 || sudo /usr/sbin/td-agent-gem install fluent-plugin-rewrite-tag-filter -v "2.2.0"',
        ].each { |cmd| backend(cmd) }

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

        upload_contents(host, conf, '/etc/td-agent/td-agent.conf')
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

      def install_yarn
        backend('sudo sh -c \"curl --silent --location https://rpm.nodesource.com/setup_10.x | bash -\"')
        backend('sudo wget https://dl.yarnpkg.com/rpm/yarn.repo -O /etc/yum.repos.d/yarn.repo')
        backend('sudo yum install -y nodejs yarn')
        self
      end

      def update_egotter
        backend('sudo cp -f ./setup/etc/init.d/egotter /etc/init.d')
        self
      end

      def update_crontab
        backend('crontab -r || :')
        backend('sudo crontab -r || :')
        upload_file(@name, './setup/etc/crontab', '/etc/crontab')
        backend('sudo chown root:root /etc/crontab')
        self
      end

      def update_nginx
        backend('sudo cp -f ./setup/etc/nginx/nginx.conf /etc/nginx/nginx.conf')
        self
      end

      def update_puma
        backend('sudo cp -f ./setup/etc/init.d/puma /etc/init.d')
        self
      end

      def update_sidekiq
        backend('sudo cp -f ./setup/etc/init.d/sidekiq* /etc/init.d')
        backend('sudo cp -f ./setup/etc/init/sidekiq* /etc/init')
        backend('sudo cp -f ./setup/etc/init.d/patient_sidekiqctl.rb /etc/init.d')
        self
      end

      def update_datadog
        frontend("rsync -auz ./setup/etc/datadog-agent/conf.d/sidekiq.d/conf.yaml #{@name}:/var/egotter/datadog.sidekiq.conf.yaml.tmp")
        backend('test -e "/etc/datadog-agent/conf.d/sidekiq.d" || sudo mkdir /etc/datadog-agent/conf.d/sidekiq.d')
        backend('sudo mv /var/egotter/datadog.sidekiq.conf.yaml.tmp /etc/datadog-agent/conf.d/sidekiq.d/conf.yaml')
        self
      end
    end

    class Web < Task
      attr_reader :instance

      def initialize(id)
        @id = id
        @instance = ::DeployRuby::Aws::Instance.retrieve(id)
        super(@instance.name)
      end

      def sync
        update_misc.
            update_env.
            install_yarn.
            upload_file(@name, './setup/root/.irbrc', '/root/.irbrc').
            pull_latest_code.
            precompile.
            update_egotter.
            update_crontab.
            update_nginx.
            update_puma.
            install_td_agent(@name, './setup/etc/td-agent/td-agent.web.conf.erb')
      end

      def install
        sync.restart_processes
      rescue => e
        logger.error red("Terminate #{@id} since #{e.class} is raised")
        ::DeployRuby::Aws::EC2.new.terminate_instance(@id)
        raise
      end

      def update_env
        upload_env(@name, 'env/web.env.enc')
      end

      def update_misc
        [
            'sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a stop',
            'sudo yum install -y httpd-tools',
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
        super(@instance.name)
      end

      def sync
        update_misc.
            update_env.
            upload_file(@name, './setup/root/.irbrc', '/root/.irbrc').
            pull_latest_code.
            update_datadog.
            update_egotter.
            update_crontab.
            update_sidekiq.
            install_td_agent(@name, './setup/etc/td-agent/td-agent.sidekiq.conf.erb')
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
        upload_env(@name, 'env/sidekiq.env.enc')
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
            'sudo start sidekiq_import',
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
            'sudo stop sidekiq_import || :',
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
        upload_env(@name, 'env/sidekiq_prompt_reports.env.enc')
      end

      def restart_processes
        [
            'sudo service td-agent restart',
            'sudo service nginx stop || :',
            'sudo service puma stop || :',
            'sudo stop sidekiq_import || :',
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
        super(@instance.name)
      end

      def sync
        update_misc.
            upload_file(@name, './setup/root/.irbrc', '/root/.irbrc').
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
            'sudo yum install -y httpd-tools',
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
            'sudo stop sidekiq_import || :',
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