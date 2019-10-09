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

class Util
  class << self
    def print_pid(pidfile)
      `cat #{pidfile}`.to_i
    end

    def print_process(params)
      pid = params[:pid] || print_pid(params[:pidfile])
      `ps -o command= -p #{pid}`
    end

    def pidfile_exists?(pidfile)
      File.exists?(pidfile)
    end

    def process_exists?(params)
      pid = params[:pid] || print_pid(params[:pidfile])
      Process.kill(0, pid)
    rescue Errno::ESRCH => e
      false
    end

    def success(state, name)
      puts "#{state} #{name} [ \e[32m OK \e[0m ]"
    end

    def failure(state, name)
      puts "#{state} #{name} [ \e[31m FAILED \e[0m ]"
    end
  end
end

class SidekiqCtl
  class << self
    def quiet(pidfile)
      result = `#{SIDEKIQCTL_CMD} quiet #{pidfile} 2>&1`
      puts "sidekiqctl: #{result}"
    end

    def quiet?(pidfile)
      Util.pidfile_exists?(pidfile) &&
          Util.process_exists?(pidfile: pidfile) &&
          Util.print_process(pidfile: pidfile).strip.match?(/\[0 of [0-9]+ busy\] stopping/)
    end

    def stop(pidfile)
      result = `#{SIDEKIQCTL_CMD} stop #{pidfile} 2>&1`
      puts "sidekiqctl: #{result}"
    end

    def start(options)
      cmd = "#{SIDEKIQ_CMD} -d -C #{options[:conf]}"
      result = `sudo -u #{options[:user]} sh -c "#{cmd}"`
      puts "sidekiq: #{result}"
    end

    def start?(pidfile)
      Util.pidfile_exists?(pidfile) &&
          Util.process_exists?(pidfile: pidfile) &&
          Util.print_process(pidfile: pidfile).strip.match?(/\[[0-9]+ of [0-9]+ busy\]$/)
    end
  end
end

class Patient
  class << self
    def status(pidfile)
      if Util.pidfile_exists?(pidfile)
        if Util.process_exists?(pidfile: pidfile)
          pid = Util.print_pid(pidfile)
          puts "#{pid} #{Util.print_process(pid: pid)}"
        else
          puts 'process dead but pidfile exists'
        end
      else
        puts "pidfile doesn't exist"
      end
    end

    def quiet(pidfile)
      if Util.pidfile_exists?(pidfile)
        if Util.process_exists?(pidfile: pidfile)
          pid = Util.print_pid(pidfile)

          max_count = 10
          sleep_interval = 2

          max_count.times.with_index do |i|
            SidekiqCtl.quiet(pidfile)
            break if SidekiqCtl.quiet?(pidfile)
            puts "waiting to be quiet #{Util.print_process(pid: pid)} (#{i + 1}/#{max_count})"
            sleep sleep_interval
          end

          if SidekiqCtl.quiet?(pidfile)
            true
          else
            puts 'retries have been exhausted'
            false
          end
        else
          puts 'process dead but pidfile exists'
          false
        end
      else
        puts "pidfile doesn't exist"
        false
      end
    end

    def stop(pidfile)
      if Util.pidfile_exists?(pidfile)
        if Util.process_exists?(pidfile: pidfile)
          pid = Util.print_pid(pidfile)

          max_count = 10
          sleep_interval = 2

          max_count.times.with_index do |i|
            SidekiqCtl.stop(pidfile) if Util.pidfile_exists?(pidfile)
            break if !Util.pidfile_exists?(pidfile) && !Util.process_exists?(pid: pid)
            puts "waiting to stop #{Util.print_process(pid: pid)} (#{i + 1}/#{max_count})"
            sleep sleep_interval
          end

          if Util.pidfile_exists?(pidfile)
            puts 'pidfile exists'
            false
          elsif Util.process_exists?(pid: pid)
            puts "process doesn't dead"
            false
          else
            true
          end
        else
          puts 'process dead but pidfile exists'
          false
        end
      else
        puts "pidfile doesn't exist"
        false
      end
    end

    def start(pidfile, options)
      if Util.pidfile_exists?(pidfile)
        if Util.process_exists?(pidfile: pidfile)
          puts 'process exists'
          false
        else
          puts 'process dead but pidfile exists'
          false
        end
      else
        SidekiqCtl.start(options)

        max_count = 10
        sleep_interval = 2

        max_count.times.with_index do |i|
          break if SidekiqCtl.start?(pidfile)
          puts "waiting to start (#{i + 1}/#{max_count})"
          sleep sleep_interval
        end

        if SidekiqCtl.start?(pidfile)
          true
        else
          puts "process hasn't started yet"
          false
        end
      end
    end
  end
end

class Process
  class << self
    def quiet(pidfile, options)
      if Patient.quiet(pidfile)
        Util.success('being quiet', options[:name])
      else
        Util.failure('being quiet', options[:name])
        exit 1
      end
    end

    def stop(pidfile, options)
      if Patient.quiet(pidfile) && Patient.stop(pidfile)
        Util.success('stopping', options[:name])
      else
        Util.failure('stopping', options[:name])
        exit 1
      end
    end

    def force_stop(pidfile, options)
      if Patient.stop(pidfile)
        Util.success('force stopping', options[:name])
      else
        Util.failure('force stopping', options[:name])
        exit 1
      end
    end

    def force_restart(pidfile, options)
      if Patient.stop(pidfile) && Patient.start(pidfile, options)
        Util.success('force restarting', options[:name])
      else
        Util.failure('force restarting', options[:name])
        exit 1
      end
    end

    def start(pidfile, options)
      if Patient.start(pidfile, options)
        Util.success('starting', options[:name])
      else
        Util.failure('starting', options[:name])
        exit 1
      end
    end

    def restart(pidfile, options)
      if Patient.quiet(pidfile) && Patient.stop(pidfile) && Patient.start(pidfile, options)
        Util.success('restarting', options[:name])
      else
        Util.failure('restarting', options[:name])
        exit 1
      end
    end

    def status(pidfile)
      unless Patient.status(pidfile)
        exit 1
      end
    end
  end
end

params = ARGV.getopts('e:', 'dir:', 'user:', 'name:', 'state:')

rails_env = params['e']
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
SIDEKIQ_CMD = "cd #{app_root} && RAILS_ENV=#{rails_env} #{bundle_cmd} exec #{ruby_cmd} #{sidekiq_cmd}"

case state
when 'quiet'         then Process.quiet(pidfile, options)
when 'stop'          then Process.stop(pidfile, options)
when 'force-stop'    then Process.force_stop(pidfile, options)
when 'force-restart' then Process.force_restart(pidfile, options)
when 'start'         then Process.start(pidfile, options)
when 'restart'       then Process.restart(pidfile, options)
when 'status'        then Process.status(pidfile)
end
