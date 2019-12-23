module Egotter
  module Install
    module Util
      def yellow(str)
        puts "\e[33m#{str}\e[0m"
      end

      def green(str)
        puts "\e[32m#{str}\e[0m"
      end

      def red(str)
        puts "\e[31m#{str}\e[0m"
      end

      def install_td_agent(host, src)
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

        upload_contents(host, conf, '/etc/td-agent/td-agent.conf')
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
        yellow("localhost #{cmd}")
        system(cmd, exception: exception)
      end

      def exec_command(host, cmd, dir: '/var/egotter', exception: true)
        raise 'Hostname is empty.' if host.to_s.empty?
        green("#{host} #{cmd}")
        system('ssh', host, "cd #{dir} && #{cmd}", exception: exception).tap { |r| puts r }
      end
    end

    class Task
      include Util

      def initialize(name)
        @name = name
      end

      def install
        raise NotImplementedError
      end

      def run_command(cmd, exception: true)
        exec_command(@name, cmd, exception: exception)
      end

      def pull_latest_code
        run_command('git pull origin master >/dev/null')
        run_command('bundle check || bundle install --quiet --path .bundle --without test development')
        self
      end

      def update_egotter
        run_command('sudo cp -f ./setup/etc/init.d/egotter /etc/init.d')
        self
      end

      def update_crontab
        run_command('crontab -r || :')
        run_command('sudo crontab -r || :')
        upload_file(@name, './setup/etc/crontab', '/etc/crontab')
        run_command('sudo chown root:root /etc/crontab')
        self
      end

      def update_puma
        run_command('sudo cp -f ./setup/etc/init.d/puma /etc/init.d')
        self
      end

      def update_sidekiq
        run_command('sudo cp -f ./setup/etc/init.d/sidekiq* /etc/init.d')
        run_command('sudo cp -f ./setup/etc/init/sidekiq* /etc/init')
        run_command('sudo cp -f ./setup/etc/init.d/patient_sidekiqctl.rb /etc/init.d')
        self
      end

      def update_datadog
        system("rsync -auz ./setup/etc/datadog-agent/conf.d/sidekiq.d/conf.yaml #{@name}:/var/egotter/datadog.sidekiq.conf.yaml.tmp")
        run_command('test -e "/etc/datadog-agent/conf.d/sidekiq.d" || sudo mkdir /etc/datadog-agent/conf.d/sidekiq.d')
        run_command('sudo mv /var/egotter/datadog.sidekiq.conf.yaml.tmp /etc/datadog-agent/conf.d/sidekiq.d/conf.yaml')
        self
      end
    end

    class Web < Task
      def initialize(id, name)
        @id = id
        super(name)
      end

      def install
        update_env.
            upload_file(@name, './setup/root/.irbrc', '/root/.irbrc').
            pull_latest_code.
            update_egotter.
            update_crontab.
            update_puma.
            install_td_agent(@name, './setup/etc/td-agent/td-agent.web.conf.erb').
            restart_processes
      rescue => e
        red("Terminate #{@id} as #{e.class} is raised")
        ::Egotter::Aws::EC2.terminate_instance(@id)
        raise
      end

      def update_env
        upload_env(@name, 'env/web.env.enc')
      end

      def restart_processes
        [
            'sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a stop',
            'sudo rm -rf /var/tmp/aws-mon/*',
            'sudo rm -rf /var/egotter/tmp/cache/*',
            'sudo rm -rf /var/egotter/log/*',
            'RAILS_ENV=production bundle exec rake assets:precompile',
            'RAILS_ENV=production bundle exec rake assets:sync:download',
            'sudo service td-agent restart',
            'sudo service nginx restart',
            'sudo service puma restart',
            'sudo restart datadog-agent',
        ].each do |cmd|
          run_command(cmd)
        end

        self
      end
    end

    class Sidekiq < Task
      def initialize(id, name)
        @id = id
        super(name)
      end

      def install
        update_env.
            upload_file(@name, './setup/root/.irbrc', '/root/.irbrc').
            pull_latest_code.
            update_datadog.
            update_egotter.
            update_crontab.
            update_sidekiq.
            install_td_agent(@name, './setup/etc/td-agent/td-agent.sidekiq.conf.erb').
            restart_processes
      rescue => e
        if @id
          red("Terminate #{@id} as #{e.class} is raised")
          before_terminate
          ::Egotter::Aws::EC2.terminate_instance(@id)
        end
        raise
      end

      def update_env
        upload_env(@name, 'env/sidekiq.env.enc')
      end

      def restart_processes
        [
            'sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a stop',
            'sudo rm -rf /var/tmp/aws-mon/*',
            'sudo rm -rf /var/egotter/tmp/cache/*',
            'sudo rm -rf /var/egotter/log/*',
            'sudo service td-agent restart',
            'sudo service nginx stop',
            'sudo service puma stop',
            'sudo start sidekiq',
            'sudo start sidekiq_import',
            'sudo start sidekiq_misc',
            'sudo start sidekiq_prompt_reports',
            'sudo restart datadog-agent',
        ].each do |cmd|
          run_command(cmd)
        end

        self
      end

      def before_terminate
        [
            'sudo stop sidekiq || :',
            'sudo stop sidekiq_import || :',
            'sudo stop sidekiq_misc || :',
            'sudo stop sidekiq_prompt_reports || :',
        ].each do |cmd|
          run_command(cmd)
        end
      end
    end
  end

end