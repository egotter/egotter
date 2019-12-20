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
            update_env(@name, 'env/web.env.enc').
            install_td_agent(@name).
            restart_processes
      rescue => e
        terminate if @id
        raise
      end

      def launch
        @id, @public_ip = launch_instance(template: @template, security_group: @security_group, subnet: @subnet, name: @name)

        self
      end

      def restart_processes
        [
            'sudo rm -rf /var/tmp/aws-mon/*',
            'sudo rm -rf /var/egotter/tmp/cache/*',
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