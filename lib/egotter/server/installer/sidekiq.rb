require_relative '../ec2_util'
require_relative './base'

module Egotter
  module Server
    module Installer
      class Sidekiq < Base
        def install
          append_to_ssh_config(@id, @name, @public_ip).
              test_ssh_connection(@name).
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
            ::Egotter::Server::Ec2Util.terminate_instance(@id)
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
              'sudo start datadog-agent',
          ].each do |cmd|
            run_command(cmd)
          end

          self
        end

        def before_terminate
          %w(sidekiq sidekiq_import sidekiq_misc sidekiq_prompt_reports).each do |name|
            cmd = %Q(sudo service #{name} status && sudo service #{name} stop || echo "Not running")
            run_command(cmd)
          end
        end
      end
    end
  end
end