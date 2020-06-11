require "open3"

require_relative './util'

module Tasks
  module ReleaseTask
    class Base
      include ::Tasks::Util

      attr_reader :action

      def initialize(host)
        @action = :release
        @instance = ::DeployRuby::Aws::Instance.retrieve_by(name: host)
      end
    end

    class Web < Base
      def initialize(host)
        super
        @target_group = ::DeployRuby::Aws::TargetGroup.new(ENV['AWS_TARGET_GROUP'])
      end

      def run
        ssh_connection_test(@instance.public_ip)
        @target_group.deregister(@instance.id)

        [
            'git fetch origin',
            'git log --oneline master..origin/master',
            'git pull origin master',
            'bundle check || bundle install --path .bundle --without test development',
            'RAILS_ENV=production bundle exec rake assets:precompile',
            'sudo cp ./setup/etc/nginx/nginx.conf /etc/nginx/nginx.conf',
            'sudo cp ./setup/etc/init.d/puma /etc/init.d/',
            'sudo cp ./setup/etc/init.d/egotter /etc/init.d/',
            'sudo service nginx restart',
            'sudo service puma restart',
            'ab -n 500 -c 10 http://localhost:80/'
        ].each do |cmd|
          exec_command(@instance.public_ip, cmd)
        end

        @target_group.register(@instance.id)
      end
    end

    class Sidekiq < Base
      def initialize(host)
        super
      end

      def run
        ssh_connection_test(@instance.public_ip)

        [
            'git fetch origin',
            'git log --oneline master..origin/master',
            'git pull origin master',
            'bundle check || bundle install --path .bundle --without test development',
            'sudo cp ./setup/etc/init/sidekiq* /etc/init/',
            'sudo cp ./setup/etc/init.d/egotter /etc/init.d/',
            'sudo restart sidekiq_misc || :',
            'sudo restart sidekiq_misc_workers || :',
            'sudo restart sidekiq_prompt_reports || :',
            'sudo restart sidekiq_prompt_reports_workers || :',
            'sudo restart sidekiq || :',
            'sudo restart sidekiq_workers || :',
        ].each do |cmd|
          exec_command(@instance.public_ip, cmd)
        end
      end
    end
  end
end
