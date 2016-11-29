module Tasks
  class Base
    attr_accessor :cli_or_web

    def initialize(cli_or_web)
      self.cli_or_web = cli_or_web
    end

    def self.invoke(*args)
      raise NotImplementedError
    end

    def process_jobs(worker_klass, user_ids, deadline)
      return if user_ids.blank?

      deadline =
        case
          when deadline.nil? then nil
          when deadline.match(/\d+\.(minutes?|hours?)/) then Time.zone.now + eval(deadline)
          else Time.zone.parse(deadline)
        end

      user_ids =
        case
          when user_ids.include?('..') then Range.new(*user_ids.split('..').map(&:to_i))
          when user_ids.include?(',') then user_ids.split(',').map(&:to_i)
          else [user_ids.to_i]
        end

      authorized = User.where(id: user_ids, authorized: true).to_a
      active = User.active(14).where(id: authorized.map(&:id)).to_a

      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end if cli?

      start_time = Time.zone.now
      log 'started:'
      log "  start: #{start_time}, user_ids: #{user_ids.size}, authorized: #{authorized.size}, active: #{active.size}, deadline: #{deadline}"

      processed = 0
      fatal = false
      errors = []

      active.map(&:id).each.with_index do |user_id, i|
        start = Time.zone.now
        failed = false
        begin
          worker_klass.new.perform(user_id)
          sleep_if_delay_occurs
        rescue => e
          failed = true
          errors << {time: Time.zone.now, error: e, user_id: user_id}
          fatal = errors.select { |error| error[:time] > 60.seconds.ago }.size >= 10
        end
        processed += 1

        print_jobs(i, user_id: user_id, process_start: start_time, job_start: start, deadline: deadline, failed: failed)

        break if (deadline && Time.zone.now > deadline) || sigint || fatal
      end

      if errors.any?
        log 'errors:'
        errors.each { |error| log "  #{error[:time]}: #{error[:user_id]}, #{error[:error].class} #{error[:error].message}" }
      end

      log "#{(sigint || fatal ? 'suspended:' : 'finished:')}"
      log "  start: #{start_time}, finish: #{Time.zone.now}, processed: #{processed}"
    end

    private

    def sleep_if_delay_occurs(seconds = 5)
      queues = Sidekiq::Queue.all
      workers = Sidekiq::Workers.new
      if queues.map(&:size).sum > workers.size * 3 || queues.map(&:latency).max > 3
        log "SLEEP #{seconds} seconds, workers: #{workers.size}, queues: #{queues.map(&:size).sum}, max_latency: #{queues.map(&:latency).max}"
        sleep seconds
      end
    end

    def print_jobs(sequence, user_id:, process_start:, job_start:, deadline:, failed:)
      if sequence % 10 == 0
        avg = ", #{'%4.1f' % ((Time.zone.now - process_start) / (sequence + 1))} seconds/user"
        elapsed = ", #{'%.1f' % (Time.zone.now - process_start)} seconds elapsed"
        remaining = deadline ? ", #{'%.1f' % (deadline - Time.zone.now)} seconds remaining" : ''
      else
        avg = elapsed = remaining = ''
      end
      status = failed ? ', failed' : ''
      log "#{Time.zone.now}: #{user_id}, #{'%4.1f' % (Time.zone.now - job_start)} seconds#{avg}#{elapsed}#{remaining}#{status}"
    end

    def cli?
      cli_or_web == 'cli'
    end

    def log(str)
      @logger ||=
        Logger.new(cli? ? STDOUT : Rails.root.join('log', 'twitter_users_send_prompt_reports.log'))
      @logger.info str
    end
  end
end
