module Egotter
  module Server
    class Sidekiq
      include Util

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
            append_to_ssh_config(@id, @name, @public_ip).
            test_ssh_connection(@name).
            update_env.
            update_datadog.
            update_egotter.
            update_sidekiq.
            install_td_agent(@name, './setup/etc/td-agent/td-agent.sidekiq.conf.erb').
            restart_processes
      rescue => e
        if @id
          AwsUtil.red("Terminate #{@id} as #{e.class} is raised")
          terminate
        end
        raise
      end

      def launch
        @id, @public_ip = launch_instance(template: @template, security_group: @security_group, subnet: @subnet, name: @name)

        self
      end

      def update_env
        upload_env(@name, 'env/sidekiq.env.enc')
      end

      def update_egotter
        run_command('sudo cp -f ./setup/etc/init.d/egotter /etc/init.d')

        self
      end

      def update_sidekiq
        [
            'sudo cp -f ./setup/etc/init.d/sidekiq* /etc/init.d',
            'sudo cp -f ./setup/etc/init.d/patient_sidekiqctl.rb /etc/init.d',
        ].each do |cmd|
          run_command(cmd)
        end

        self
      end

      def update_datadog
        system("rsync -auz ./setup/etc/datadog-agent/conf.d/sidekiq.d/conf.yaml #{@name}:/var/egotter/datadog.sidekiq.conf.yaml.tmp")
        run_command('test -e "/etc/datadog-agent/conf.d/sidekiq.d" || sudo mkdir /etc/datadog-agent/conf.d/sidekiq.d')
        run_command('sudo mv /var/egotter/datadog.sidekiq.conf.yaml.tmp /etc/datadog-agent/conf.d/sidekiq.d/conf.yaml')

        self
      end

      def restart_processes
        [
            'sudo rm -rf /var/tmp/aws-mon/*',
            'sudo rm -rf /var/egotter/tmp/cache/*',
            'sudo rm -rf /var/egotter/log/*',
            'git pull origin master >/dev/null',
            'bundle check || bundle install --quiet --path .bundle --without test development',
            'sudo service td-agent restart',
            'sudo service nginx stop',
            'sudo service puma stop',
            'sudo service sidekiq start',
            'sudo service sidekiq_import start',
            'sudo service sidekiq_misc start',
            'sudo service sidekiq_prompt_reports start',
        ].each do |cmd|
          run_command(cmd)
        end

        self
      end

      def terminate
        %w(sidekiq sidekiq_import sidekiq_misc sidekiq_prompt_reports).each do |name|
          cmd = %Q(sudo service #{name} status && sudo service #{name} stop || echo "Not running")
          run_command(cmd)
        end

        terminate_instance(@id)
      end

      def run_command(cmd, exception: true)
        exec_command(@name, cmd, exception: exception)
      end
    end
  end
end