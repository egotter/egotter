#!/usr/bin/env ruby

require 'optparse'

module Deploy
  class Web
    CMD = [
        'git pull origin master',
        'bundle check || bundle install --path .bundle --without test development',
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
          puts "\e[32m#{host} #{cmd}\e[0m" # Green
          puts system('ssh', host, "cd #{current_dir} && #{cmd}", exception: true)
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
        'git pull origin master',
        'bundle check || bundle install --path .bundle --without test development',
        ['sudo service sidekiq_misc status'          , 'sudo service sidekiq_misc restart'],
        ['sudo service sidekiq_prompt_reports status', 'sudo service sidekiq_prompt_reports restart'],
        ['sudo service sidekiq status'               , 'sudo service sidekiq restart'],
        ['sudo service sidekiq_import status'        , 'sudo service sidekiq_import restart'],
        ['sudo service sidekiq_follow status'        , 'sudo service sidekiq_follow restart'],
        ['sudo service sidekiq_unfollow status'      , 'sudo service sidekiq_unfollow restart'],
    ]

    def current_dir
      '/var/egotter'
    end

    def hosts
      %w(
        egotter_web
        egotter_sidekiq5
      )
    end

    def run
      hosts.each do |host|
        CMD.each do |cmd|
          if cmd.class == Array
            cmd.each do |c|
              puts "\e[32m#{host} #{c}\e[0m" # Green
              break unless (system('ssh', host, "cd #{current_dir} && #{c}", exception: true) rescue false)
            end
          else
            puts "\e[32m#{host} #{cmd}\e[0m" # Green
            puts system('ssh', host, "cd #{current_dir} && #{cmd}", exception: true)
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
