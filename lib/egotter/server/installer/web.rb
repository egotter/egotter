require_relative '../ec2_util'
require_relative './base'

module Egotter
  module Server
    module Installer
      class Web < Base
        def install
          append_to_ssh_config(@id, @name, @public_ip).
              test_ssh_connection(@name).
              update_env.
              upload_file(@name, './setup/root/.irbrc', '/root/.irbrc').
              pull_latest_code.
              update_egotter.
              update_crontab.
              install_td_agent(@name, './setup/etc/td-agent/td-agent.web.conf.erb').
              restart_processes
        rescue => e
          red("Terminate #{@id} as #{e.class} is raised")
          ::Egotter::Server::Ec2Util.terminate_instance(@id)
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
    end
  end
end