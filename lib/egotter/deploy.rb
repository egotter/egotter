module Egotter
  module Deploy
    class Task
      attr_reader :host

      def initialize(host)
        @host = host
      end

      def current_dir
        '/var/egotter'
      end

      def frontend(cmd)
        execute(cmd)
      end

      def backend(cmd)
        execute('ssh', host, "cd #{current_dir} && #{cmd}")
      end

      def ssh_connection_test
        backend('echo "ssh connection test" >/dev/null')
      end

      private

      def execute(*cmd)
        green(cmd.join(' '))
        puts system(*cmd, exception: true)
      end

      def green(str)
        puts "\e[32m#{str}\e[0m"
      end
    end

    class Web < Task
      def before_deploy
        ssh_connection_test
      end

      def deploy
        before_deploy

        [
            'git fetch origin',
            'git log --oneline master..origin/master',
            'git pull origin master',
            'bundle check || bundle install --path .bundle --without test development',
            'RAILS_ENV=production bundle exec rake assets:precompile',
            'sudo cp ./setup/etc/init.d/puma /etc/init.d/',
            'sudo cp ./setup/etc/init.d/egotter /etc/init.d/',
            'sudo service puma restart',
        ].each do |cmd|
          backend(cmd)
        end
      end
    end

    class Sidekiq < Task
      def before_deploy
        ssh_connection_test
      end

      def deploy
        before_deploy

        [
            'git fetch origin',
            'git log --oneline master..origin/master',
            'git pull origin master',
            'bundle check || bundle install --path .bundle --without test development',
            'sudo cp ./setup/etc/init/sidekiq* /etc/init/',
            'sudo cp ./setup/etc/init.d/egotter /etc/init.d/',
            'sudo restart sidekiq_misc || :',
            'sudo restart sidekiq_prompt_reports || :',
            'sudo restart sidekiq || :',
            'sudo restart sidekiq_import || :',
            'sudo restart sidekiq_follow || :',
            'sudo restart sidekiq_unfollow || :',
        ].each do |cmd|
          backend(cmd)
        end
      end
    end
  end
end
