#!/usr/bin/env ruby

require 'optparse'

module Deploy
  module Util
    def green(str)
      puts "\e[32m#{str}\e[0m"
    end
  end

  class Task
    include Util

    attr_reader :host

    def initialize(host)
      @host = host
    end

    def current_dir
      '/var/egotter'
    end

    def execute(*cmd)
      green(cmd.join(' '))
      puts system(*cmd, exception: true)
    end

    def frontend(cmd)
      execute(cmd)
    end

    def backend(cmd)
      execute('ssh', host, "cd #{current_dir} && #{cmd}")
    end
  end

  class Web < Task
    def before_deploy
      backend('echo "ssh connection test"')
    end

    def deploy
      before_deploy

      [
          'git fetch origin',
          'git pull origin master',
          'bundle check || bundle install --path .bundle --without test development',
          'RAILS_ENV=production bundle exec rake assets:precompile',
          'sudo cp ./setup/etc/init.d/puma /etc/init.d/',
          'sudo service puma restart',
      ].each do |cmd|
        backend(cmd)
      end
    end
  end

  class Sidekiq < Task
    def before_deploy
      backend('echo "ssh connection test"')
    end

    def deploy
      before_deploy

      [
          'git fetch origin',
          'git pull origin master',
          'bundle check || bundle install --path .bundle --without test development',
          'sudo cp ./setup/etc/init/sidekiq* /etc/init/',
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

if __FILE__ == $0
  STDOUT.sync = true

  params = ARGV.getopts('r:', 'role:', 'hosts:')
  hosts = params['hosts'].split(',')

  case params['role']
  when 'web'
    hosts.each { |host| Deploy::Web.new(host).deploy }
    system("git tag deploy-web-all-#{Time.now.to_i}")
    system('git push origin --tags')

  when 'sidekiq'
    hosts.each { |host| Deploy::Sidekiq.new(host).deploy }
    system("git tag deploy-sidekiq-all-#{Time.now.to_i}")
    system('git push origin --tags')

  else
    puts "Invalid #{params.inspect}"
  end
end
