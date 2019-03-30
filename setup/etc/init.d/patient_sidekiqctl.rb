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
  `ps -o command= -p #{pid}`
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

def quiet(pidfile)
  result = `#{SIDEKIQCTL_CMD} quiet #{pidfile}`
  puts "sidekiqctl: #{result}" unless result.empty?
end

def quiet?(pidfile)
  process_exists?(pidfile: pidfile) && print_process(pidfile: pidfile).strip.match?(/\[0 of [0-9]+ busy\] stopping/)
end

def stop(pidfile)
  result = `#{SIDEKIQCTL_CMD} stop #{pidfile}`
  puts "sidekiqctl: #{result}" unless result.empty?
end

def start(options)
  result = `sudo -u #{options[:user]} sh -c "#{SIDEKIQ_CMD} -d -C #{options[:conf]}"`
  puts "sidekiq: #{result}" unless result.empty?
end

def start?(pidfile)
  pidfile_exists?(pidfile) && process_exists?(pidfile: pidfile) && print_process(pidfile: pidfile).strip.match?(/\[0 of [0-9]+ busy\]$/)
end

def status(pidfile)
  pid = print_pid(pidfile)
  puts "#{pid} #{print_process(pid: pid)}"
end

def do_quiet(pidfile, options)
  if pidfile_exists?(pidfile)
    if process_exists?(pidfile: pidfile)
      10.times do
        quiet(pidfile)
        break if quiet?(pidfile)
        puts "waiting to be quiet #{print_process(pidfile: pidfile)}"
        sleep 2
      end

      if quiet?(pidfile)
        puts "being quiet #{options[:name]} [ #{green('OK')} ]"
      else
        puts "being quiet #{options[:name]} [ #{red('FAILED')} ]"
        exit 1
      end
    else
      puts 'process dead but pid file exists'
      exit 1
    end
  else
    puts "pid file doesn't exist"
    exit 1
  end
end

def do_stop(pidfile, print_success = true, **options)
  if pidfile_exists?(pidfile)
    if process_exists?(pidfile: pidfile)
      pid = print_pid(pidfile)

      10.times do
        quiet(pidfile)
        break if quiet?(pidfile)
        puts "waiting to be quiet #{print_process(pid: pid)}"
        sleep 2
      end

      if quiet?(pidfile)
        puts "being quiet #{options[:name]} [ #{green('OK')} ]" if print_success
      else
        puts "'being quiet #{options[:name]} [ #{red('FAILED')} ]'"
        exit 1
      end

      10.times do
        stop(pidfile) if pidfile_exists?(pidfile)
        break if !pidfile_exists?(pidfile) && !process_exists?(pid: pid)
        puts "waiting to stop #{print_process(pid: pid)}"
        sleep 2
      end

      if !pidfile_exists?(pidfile) && !process_exists?(pid: pid)
        puts "stopping #{options[:name]} [ #{green('OK')} ]" if print_success
      else
        puts "stopping #{options[:name]} [ #{red('FAILED')} ]"
        exit 1
      end
    else
      puts 'process dead but pid file exists'
      exit 1
    end
  else
    puts "pid file doesn't exist"
    exit 1
  end
end

def do_start(pidfile, print_success = true, **options)
  if pidfile_exists?(pidfile)
    if process_exists?(pidfile: pidfile)
      puts 'process exists'
      exit 1
    else
      puts 'process dead but pid file exists'
      exit 1
    end
  else
    start(options)
    10.times do
      break if start?(pidfile)
      puts "waiting to start"
      sleep 2
    end

    if start?(pidfile)
      puts "starting #{options[:name]} [ #{green('OK')} ]" if print_success
    else
      puts "starting #{options[:name]} [ #{red('FAILED')} ]"
      exit 1
    end
  end
end

def do_restart(pidfile, options)
  do_stop(pidfile, false, options)
  do_start(pidfile, false, options)
  puts "restarting #{options[:name]} [ #{green('OK')} ]"
end

def do_status(pidfile)
  if pidfile_exists?(pidfile)
    if process_exists?(pidfile: pidfile)
      status(pidfile)
    else
      puts 'process dead but pid file exists'
      exit 1
    end
  else
    puts "pid file doesn't exist"
    exit 1
  end
end

def green(str)
  "\e[32m#{str}\e[0m"
end

def red(str)
  "\e[31m#{str}\e[0m"
end

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
when 'quiet'   then do_quiet(pidfile, options)
when 'stop'    then do_stop(pidfile, options)
when 'start'   then do_start(pidfile, options)
when 'restart' then do_restart(pidfile, options)
when 'status'  then do_status(pidfile)
end
