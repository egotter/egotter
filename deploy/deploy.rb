require_relative './lib/aws'

module DeployTask
  def build(params)
    role = params['role']
    hosts = params['hosts'].split(',')

    if role == 'web'
      hosts.map { |host| WebTask.new(host) }
    elsif role == 'sidekiq'
      hosts.map { |host| SidekiqTask.new(host) }
    else
      raise "Invalid role #{role}"
    end
  end

  module_function :build

  module DSL
    def backend(host, dir, cmd)
      execute(host, "cd #{dir} && #{cmd}")
    end

    private

    def execute(host, cmd)
      puts green(cmd)
      system('ssh', host, cmd, exception: true)
    end

    def green(str)
      puts "\e[32m#{str}\e[0m"
    end
  end

  class Task
    include DSL

    attr_reader :host

    def initialize(host)
      @host = host
    end

    def current_dir
      '/var/egotter'
    end

    def backend(cmd)
      super(@host, current_dir, cmd)
    end

    def ssh_connection_test
      backend('echo "ssh connection test" >/dev/null')
    end
  end

  class WebTask < Task
    def initialize(host)
      super

      @instance = ::Egotter::Aws::Instance.retrieve_by(name: host)
      @target_group = ::Egotter::Aws::TargetGroup.new(ENV['AWS_TARGET_GROUP'])
    end

    def before_run
      ssh_connection_test
      @target_group.deregister(@instance.id)
    end

    def run
      before_run

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
      ].each do |cmd|
        backend(cmd)
      end

      after_run
    end

    def after_run
      backend('ab -n 100 -c 10 http://localhost:80/')
      @target_group.register(@instance.id)
    end
  end

  class SidekiqTask < Task
    def before_run
      ssh_connection_test
    end

    def run
      before_run

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
