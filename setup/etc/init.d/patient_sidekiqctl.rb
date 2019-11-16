#!/usr/bin/env ruby

require 'yaml'
require 'optparse'

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.4.0')
  class String
    def match?(*args)
      self.match(*args)
    end
  end
end

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
  Process.kill(0, pid)
rescue Errno::ESRCH => e
  false
end

class Sidekiqctl
  class << self
    def quiet(pidfile)
      cmd = "#{SIDEKIQCTL_CMD} quiet #{pidfile}"
      puts cmd if DEBUG
      result = `#{cmd}`
      puts "sidekiqctl: #{result}" unless result.empty?
    end

    def quiet?(pidfile)
      process_exists?(pidfile: pidfile) &&
          print_process(pidfile: pidfile).match?(/\[0 of [0-9]+ busy\] stopping/)
    end

    def stop(pidfile)
      cmd = "#{SIDEKIQCTL_CMD} stop #{pidfile}"
      puts cmd if DEBUG
      result = `#{cmd}`
      puts "sidekiqctl: #{result}" unless result.empty?
    end

    def start(options)
      cmd = "#{SIDEKIQ_CMD} -d -C #{options[:conf]}"
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
end

class Patient
  class << self
    def quiet(pidfile)
      if pidfile_exists?(pidfile)
        if process_exists?(pidfile: pidfile)
          pid = print_pid(pidfile)

          max_waiting = 30
          sleep_seconds = 2

          max_waiting.times do |i|
            Sidekiqctl.quiet(pidfile)
            break if Sidekiqctl.quiet?(pidfile)
            puts "waiting to be quiet #{print_process(pid: pid)} #{i + 1}/#{max_waiting}"
            sleep sleep_seconds
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

          max_waiting = 30
          sleep_seconds = 2

          max_waiting.times do |i|
            Sidekiqctl.stop(pidfile) if pidfile_exists?(pidfile)
            break if !pidfile_exists?(pidfile) && !process_exists?(pid: pid)
            puts "waiting to stop #{print_process(pid: pid)} #{i + 1}/#{max_waiting}"
            sleep sleep_seconds
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

        max_waiting = 30
        sleep_seconds = 2

        max_waiting.times do |i|
          break if Sidekiqctl.start?(pidfile)
          puts "waiting to start #{i + 1}/#{max_waiting}"
          sleep sleep_seconds
        end

        if Sidekiqctl.start?(pidfile)
          true
        else
          false
        end
      end
    end
  end
end

def do_quiet(pidfile, options)
  if Patient.quiet(pidfile)
    success('being quiet', options[:name])
  else
    failure('being quiet', options[:name])
    exit 1
  end
end

def do_stop(pidfile, options)
  if Patient.quiet(pidfile) && Patient.stop(pidfile)
    success('stopping', options[:name])
  else
    failure('stopping', options[:name])
    exit 1
  end
end

def do_force_stop(pidfile, options)
  if Patient.stop(pidfile)
    success('force stopping', options[:name])
  else
    failure('force stopping', options[:name])
    exit 1
  end
end

def do_start(pidfile, options)
  if Patient.start(pidfile, options)
    success('starting', options[:name])
  else
    failure('starting', options[:name])
    exit 1
  end
end

def do_restart(pidfile, options)
  if Patient.stop(pidfile) && Patient.start(pidfile, options)
    success('force restarting', options[:name])
  else
    failure('force restarting', options[:name])
    exit 1
  end
end

def do_force_restart(pidfile, options)
  if Patient.quiet(pidfile) && Patient.stop(pidfile) && Patient.start(pidfile, options)
    success('restarting', options[:name])
  else
    failure('restarting', options[:name])
    exit 1
  end
end

def do_status(pidfile)
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

def do_backtrace(pidfile)
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

def success(state, name)
  puts "#{state} #{name} [ \e[32m OK \e[0m ]"
end

def failure(state, name)
  puts "#{state} #{name} [ \e[31m FAILED \e[0m ]"
end

DEBUG = false

params = ARGV.getopts('e:', 'dir:', 'user:', 'name:', 'state:')

env = params['e']
app_root = params['dir']
user = params['user']
name = params['name']
state = params['state']

conf = File.join(app_root, "config/#{name}.yml")
pidfile = File.join(app_root, YAML.load_file(conf)[:pidfile])

options = {
    name: name,
    conf: conf,
    user: user,
}

bundle_cmd =
    if File.exists?('/usr/local/bin/bundle')
      '/usr/local/bin/bundle'
    else
      `which bundle`.strip
    end

ruby_cmd =
    if File.exists?('/usr/local/bin/ruby')
      '/usr/local/bin/ruby'
    else
      `which ruby`.strip
    end

sidekiqctl_cmd = `cd #{app_root} && #{bundle_cmd} exec #{ruby_cmd} -e "print Gem.bin_path('sidekiq', 'sidekiqctl')"`
sidekiq_cmd = `cd #{app_root} && #{bundle_cmd} exec #{ruby_cmd} -e "print Gem.bin_path('sidekiq', 'sidekiq')"`

SIDEKIQCTL_CMD = "cd #{app_root} && #{bundle_cmd} exec #{ruby_cmd} #{sidekiqctl_cmd}"
SIDEKIQ_CMD = "cd #{app_root} && RAILS_ENV=#{env} #{bundle_cmd} exec #{ruby_cmd} #{sidekiq_cmd}"

case state
when 'quiet'         then do_quiet(pidfile, options)
when 'stop'          then do_stop(pidfile, options)
when 'force-stop'    then do_force_stop(pidfile, options)
when 'start'         then do_start(pidfile, options)
when 'restart'       then do_restart(pidfile, options)
when 'force-restart' then do_restart(pidfile, options)
when 'status'        then do_status(pidfile)
when 'backtrace'     then do_backtrace(pidfile)
else print_usage
end

def print_usage
  puts <<'TEXT'
Usage:
  quiet         - Stop fetching new jobs but continue working on current jobs
  stop          - Shut down after being quiet
  force-stop    - Shut down within the default timeout (25 seconds)
  start         - 
  restart       - Stop and start
  force-restart - Force-stop and start
  status        - 
  backtrace     -
TEXT
end
