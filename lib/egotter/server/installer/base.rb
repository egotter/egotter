require_relative './util'

module Egotter
  module Server
    module Installer
      class Base
        include Util

        def initialize(name, id:, public_ip:)
          @name = name
          @id = id
          @public_ip = public_ip
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
    end
  end
end