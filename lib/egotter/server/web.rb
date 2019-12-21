module Egotter
  module Server
    class Web
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
            update_egotter.
            update_crontab.
            install_td_agent(@name, './setup/etc/td-agent/td-agent.web.conf.erb').
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
        upload_env(@name, 'env/web.env.enc')
      end

      def update_egotter
        run_command('sudo cp -f ./setup/etc/init.d/egotter /etc/init.d')
        self
      end

      def update_crontab
        run_command('crontab -r')
        run_command('sudo crontab -r')
        upload_file(@name, './setup/etc/crontab', '/etc/crontab')
        self
      end

      def restart_processes
        [
            'sudo rm -rf /var/tmp/aws-mon/*',
            'sudo rm -rf /var/egotter/tmp/cache/*',
            'sudo rm -rf /var/egotter/log/*',
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

      def terminate
        terminate_instance(@id)
      end

      def run_command(cmd, exception: true)
        exec_command(@name, cmd, exception: exception)
      end
    end
  end
end