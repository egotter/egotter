require "open3"

require_relative './util'

module Tasks
  module ReleaseTask
    class Base
      include ::Tasks::Util

      attr_reader :action

      def initialize(host)
        @action = :release
        @instance = ::Deploy::Aws::Instance.retrieve_by(name: host)
      end
    end

    class Web < Base
      def initialize(host)
        super
        @role = 'web'
        @target_group = ::Deploy::Aws::TargetGroup.new(ENV['AWS_TARGET_GROUP'])
      end

      def run
        logger.info yellow("Start #{@action} task for #{@role} server at #{@instance.public_ip}")

        ssh_connection_test(@instance.public_ip)
        @target_group.deregister(@instance.id)

        [
            'git fetch origin',
            'git log --oneline master..origin/master',
            'git pull origin master',
            'bundle config set path ".bundle"',
            'bundle config set without "test development"',
            'bundle check || bundle install',
            'RAILS_ENV=production bundle exec rake assets:precompile assets:upload',
            'sudo cp ./setup/etc/nginx/nginx.conf /etc/nginx/nginx.conf',
            'sudo cp ./setup/etc/init.d/puma /etc/init.d/',
            'sudo cp ./setup/etc/init.d/egotter /etc/init.d/',
            'sudo service nginx restart',
            'sudo restart puma && sleep 10',
            'ab -n 50 -c 2 http://localhost:80/'
        ].each do |cmd|
          exec_command(@instance.public_ip, cmd)
        end

        @target_group.register(@instance.id)

        logger.info yellow("Finish #{@action} task for #{@role} server at #{@instance.public_ip}")
      end
    end

    class Sidekiq < Base
      def initialize(host)
        super
        @role = 'sidekiq'
      end

      def run
        logger.info yellow("Start #{@action} task for #{@role} server at #{@instance.public_ip}")

        ssh_connection_test(@instance.public_ip)

        [
            'sudo stop sidekiq_misc && tail -n 6 log/sidekiq_misc.log || :',
            'sudo stop sidekiq && tail -n 6 log/sidekiq.log || :',
        ].each do |cmd|
          exec_command(@instance.public_ip, cmd)
        end

        [
            'git fetch origin',
            'git log --oneline master..origin/master',
            'git pull origin master',
            'bundle config set path ".bundle"',
            'bundle config set without "test development"',
            'bundle check || bundle install',
            'sudo cp ./setup/etc/init/sidekiq* /etc/init/',
            'sudo cp ./setup/etc/init.d/egotter /etc/init.d/',
        ].each do |cmd|
          exec_command(@instance.public_ip, cmd)
        end

        [
            'sudo start sidekiq_misc || :',
            'sudo start sidekiq || :',
        ].each do |cmd|
          exec_command(@instance.public_ip, cmd)
        end

        logger.info yellow("Finish #{@action} task for #{@role} server at #{@instance.public_ip}")
      end
    end
  end
end
