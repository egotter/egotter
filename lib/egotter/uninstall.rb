require_relative './aws/instance'

module Egotter
  module Uninstall
    module Util
      def green(str)
        puts "\e[32m#{str}\e[0m"
      end

      def exec_command(host, cmd, dir: '/var/egotter', exception: true)
        raise 'Hostname is empty.' if host.to_s.empty?
        green("#{host} #{cmd}")
        system('ssh', host, "cd #{dir} && #{cmd}", exception: exception).tap { |r| puts r }
      end
    end

    class Task
      include Util

      def initialize(name)
        @name = name
      end

      def run_command(cmd, exception: true)
        exec_command(@name, cmd, exception: exception)
      end
    end

    class Sidekiq < Task
      def initialize(id)
        @id = id
        super(::Egotter::Aws::Instance.retrieve(id).name)
      end

      def uninstall
        stop_processes
      end

      def stop_processes
        [
            'sudo stop sidekiq || :',
            'sudo stop sidekiq_import || :',
            'sudo stop sidekiq_misc || :',
            'sudo stop sidekiq_prompt_reports || :',
        ].each do |cmd|
          run_command(cmd)
        end

        self
      end
    end
  end

end