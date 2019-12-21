#!/usr/bin/env ruby

require 'yaml'
require 'optparse'

module Patient
  module Util
    module_function

    def print_pid(pidfile)
      `cat #{pidfile}`.to_i
    end

    def print_process(params)
      pid =
          if params[:pidfile]
            print_pid(params[:pidfile])
          elsif params[:pid]
            params[:pid]
          end
      `ps -o command= -p #{pid}`.strip
    end

    def pidfile_exists?(pidfile)
      File.exists?(pidfile)
    end

    def process_exists?(params)
      pid =
          if params[:pidfile]
            print_pid(params[:pidfile])
          elsif params[:pid]
            params[:pid]
          end
      ::Process.kill(0, pid)
    rescue Errno::ESRCH => e
      false
    end

    def print_usage
      puts <<~'TEXT'
        Usage:
          quiet         - Stop fetching new jobs but continue working on current jobs
          stop          - Shut down after being quiet
          force-stop    - Shut down within the -t timeout option given at start-up
          start         - 
          restart       - Stop and start
          force-restart - Force-stop and start
          status        - 
          backtrace     -
      TEXT
    end

    def pick_bundle_command
      if File.exists?('/usr/local/bin/bundle')
        '/usr/local/bin/bundle'
      else
        `which bundle`.strip
      end
    end

    def pick_ruby_command
      if File.exists?('/usr/local/bin/ruby')
        '/usr/local/bin/ruby'
      else
        `which ruby`.strip
      end
    end

    def success(state, name)
      puts "#{state} #{name} [ \e[32m OK \e[0m ]"
    end

    def failure(state, name)
      puts "#{state} #{name} [ \e[31m FAILED \e[0m ]"
    end
  end

  module Sidekiqctl
    extend Util

    module_function

    def quiet(pidfile)
      cmd = "#{SIDEKIQCTL} quiet #{pidfile}"
      puts cmd if DEBUG
      result = `#{cmd}`
      puts "sidekiqctl: #{result}" unless result.empty?
    end

    def quiet?(pidfile)
      process_exists?(pidfile: pidfile) &&
          print_process(pidfile: pidfile).match?(/\[0 of [0-9]+ busy\] stopping/)
    end

    def stop(pidfile)
      cmd = "#{SIDEKIQCTL} stop #{pidfile}"
      puts cmd if DEBUG
      result = `#{cmd}`
      puts "sidekiqctl: #{result}" unless result.empty?
    end

    def start(options)
      cmd = "#{SIDEKIQ} -d -C #{options[:conf]}"
      puts cmd if DEBUG
      result = `#{cmd}`
      puts "sidekiq: #{result}" unless result.empty?
    end

    def start?(pidfile)
      pidfile_exists?(pidfile) &&
          process_exists?(pidfile: pidfile) &&
          print_process(pidfile: pidfile).match?(/\[[0-9]+ of [0-9]+ busy\]$/)
    end

    def status(pidfile)
      pid = print_pid(pidfile)
      puts "#{pid} #{print_process(pid: pid)}"
    end

    def backtrace(pidfile)
      `kill -TTIN #{print_pid(pidfile)}`
    end
  end

  module Process
    extend Util

    module_function

    def quiet(pidfile, options)
      if Patient.quiet(pidfile)
        success('being quiet', options[:name])
      else
        failure('being quiet', options[:name])
        exit 1
      end
    end

    def stop(pidfile, options)
      if Patient.quiet(pidfile) && Patient.stop(pidfile)
        success('stopping', options[:name])
      else
        failure('stopping', options[:name])
        exit 1
      end
    end

    def force_stop(pidfile, options)
      if Patient.stop(pidfile)
        success('force stopping', options[:name])
      else
        failure('force stopping', options[:name])
        exit 1
      end
    end

    def start(pidfile, options)
      if Patient.start(pidfile, options)
        success('starting', options[:name])
      else
        failure('starting', options[:name])
        exit 1
      end
    end

    def restart(pidfile, options)
      if Patient.quiet(pidfile) && Patient.stop(pidfile) && Patient.start(pidfile, options)
        success('restarting', options[:name])
      else
        failure('restarting', options[:name])
        exit 1
      end
    end

    def force_restart(pidfile, options)
      if Patient.stop(pidfile) && Patient.start(pidfile, options)
        success('force restarting', options[:name])
      else
        failure('force restarting', options[:name])
        exit 1
      end
    end

    def status(pidfile)
      if pidfile_exists?(pidfile)
        if process_exists?(pidfile: pidfile)
          Sidekiqctl.status(pidfile)
        else
          puts 'process dead but pid file exists'
          exit 1
        end
      else
        puts "pid file doesn't exist"
        exit 1
      end
    end

    def backtrace(pidfile)
      if pidfile_exists?(pidfile)
        if process_exists?(pidfile: pidfile)
          Sidekiqctl.backtrace(pidfile)
        else
          puts 'process dead but pid file exists'
          exit 1
        end
      else
        puts "pid file doesn't exist"
        exit 1
      end
    end
  end
end

module Patient
  extend Util

  module_function

  MAX_WAITING = 60
  SLEEP = 3

  def quiet(pidfile)
    if pidfile_exists?(pidfile)
      if process_exists?(pidfile: pidfile)
        pid = print_pid(pidfile)

        MAX_WAITING.times do |i|
          Sidekiqctl.quiet(pidfile)
          break if Sidekiqctl.quiet?(pidfile)
          puts "waiting to be quiet #{print_process(pid: pid)} #{i + 1}/#{MAX_WAITING}"
          sleep SLEEP
        end

        if Sidekiqctl.quiet?(pidfile)
          true
        else
          false
        end
      else
        puts 'process dead but pid file exists'
        false
      end
    else
      puts "pid file doesn't exist"
      false
    end
  end

  def stop(pidfile)
    if pidfile_exists?(pidfile)
      if process_exists?(pidfile: pidfile)
        pid = print_pid(pidfile)
        puts print_process(pid: pid)

        MAX_WAITING.times do |i|
          Sidekiqctl.stop(pidfile) if pidfile_exists?(pidfile)
          break if !pidfile_exists?(pidfile) && !process_exists?(pid: pid)
          puts "waiting to stop #{print_process(pid: pid)} #{i + 1}/#{MAX_WAITING}"
          sleep SLEEP
        end

        if !pidfile_exists?(pidfile) && !process_exists?(pid: pid)
          true
        else
          false
        end
      else
        puts 'process dead but pid file exists'
        false
      end
    else
      puts "pid file doesn't exist"
      false
    end
  end

  def start(pidfile, options)
    if pidfile_exists?(pidfile)
      if process_exists?(pidfile: pidfile)
        puts 'process exists'
        false
      else
        puts 'process dead but pid file exists'
        false
      end
    else
      Sidekiqctl.start(options)

      MAX_WAITING.times do |i|
        break if Sidekiqctl.start?(pidfile)
        puts "waiting to start #{i + 1}/#{MAX_WAITING}"
        sleep SLEEP
      end

      if Sidekiqctl.start?(pidfile)
        true
      else
        false
      end
    end
  end
end

STDOUT.sync = true

if __FILE__ == $0
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.4.0')
    class String
      def match?(*args)
        self.match(*args)
      end
    end
  end

  params = ARGV.getopts('e:', 'env:', 'dir:', 'user:', 'name:', 'state:', 'debug')

  DEBUG = params['debug']

  if DEBUG
    puts params.inspect
  end

  env = params['env'] || params['e']
  app_root = params['dir']
  name = params['name']
  state = params['state']

  conf = File.join(app_root, "config/#{name}.yml")
  pidfile = File.join(app_root, YAML.load_file(conf)[:pidfile])

  if DEBUG
    puts conf
    puts pidfile
  end

  options = {
      name: name,
      conf: conf,
  }

  bundle = Patient::Util.pick_bundle_command
  ruby = Patient::Util.pick_ruby_command

  # Gem.bin_path(name, exec_name = nil, *requirements)
  sidekiqctl = `cd #{app_root} && #{bundle} exec #{ruby} -e "print Gem.bin_path('sidekiq', 'sidekiqctl')"`
  sidekiq = `cd #{app_root} && #{bundle} exec #{ruby} -e "print Gem.bin_path('sidekiq', 'sidekiq')"`

  SIDEKIQCTL = "cd #{app_root} && #{bundle} exec #{ruby} #{sidekiqctl}"
  SIDEKIQ = "cd #{app_root} && RAILS_ENV=#{env} #{bundle} exec #{ruby} #{sidekiq}"

  case state
  when 'quiet'         then Patient::Process.quiet(pidfile, options)
  when 'stop'          then Patient::Process.stop(pidfile, options)
  when 'force-stop'    then Patient::Process.force_stop(pidfile, options)
  when 'start'         then Patient::Process.start(pidfile, options)
  when 'restart'       then Patient::Process.restart(pidfile, options)
  when 'force-restart' then Patient::Process.force_restart(pidfile, options)
  when 'status'        then Patient::Process.status(pidfile)
  when 'backtrace'     then Patient::Process.backtrace(pidfile)
  when 'help'          then Patient::Util.print_usage
  else                      Patient::Util.print_usage
  end
end

