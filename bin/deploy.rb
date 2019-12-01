#!/usr/bin/env ruby

require 'optparse'

module Deploy
  class Web
    CMD = [
        'git pull origin master',
        'bundle install --path .bundle --without test development',
        'RAILS_ENV=production bundle exec rake assets:precompile',
        'sudo service puma restart',
    ]

    def current_dir
      '/var/egotter'
    end

    def hosts
      [3, 7].map { |id| "egotter_web#{id}" }
    end

    def run
      hosts.each do |host|
        CMD.each do |cmd|
          puts "#{host} #{cmd}"
          %x(ssh #{host} "cd #{current_dir} && #{cmd}").each_line do |line|
            puts "#{host} #{line}"
          end
        end

        unless hosts.last == host
          3.times do
            seconds = 10
            puts "Sleep in #{seconds} seconds."
            sleep seconds
          end
        end
      end

      %x(git tag deploy-web-#{Time.now.to_i})
      %x(git push origin --tags)
    end
  end

  class Sidekiq
    CMD = [
        'sudo service sidekiq_misc stop',
        'sudo service sidekiq_prompt_reports stop',
        'git pull origin master',
        'bundle',
        'sudo service sidekiq_misc start',
        'sudo service sidekiq_prompt_reports start',
        'sudo service sidekiq restart',
        'sudo service sidekiq_import restart',
    ]

    def current_dir
      '/var/egotter'
    end

    def hosts
      ['egotter_web']
    end

    def run
      hosts.each do |host|
        CMD.each do |cmd|
          puts "#{host} #{cmd}"
          %x(ssh #{host} "cd #{current_dir} && #{cmd}").each_line do |line|
            puts "#{host} #{line}"
          end
        end
      end

      %x(git tag deploy-sidekiq-#{Time.now.to_i})
      %x(git push origin --tags)
    end
  end
end

STDOUT.sync = true

params = ARGV.getopts('r:', 'role:')

if params['role'] == 'web'
  Deploy::Web.new.run
elsif params['role'] == 'sidekiq'
  Deploy::Sidekiq.new.run
else
  puts "Invalid #{params.inspect}"
end
