class SkippedCreateTwitterDBUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(*args)
    raise 'Do nothing'
  end

  class << self
    def restart_jobs(limit: 100, sync: true)
      processed = 0

      Sidekiq::Queue.new(self).each do |job|
        if sync
          CreateTwitterDBUserWorker.new.perform(*job.args)
        else
          CreateTwitterDBUserWorker.perform_async(*job.args)
        end

        job.delete
        processed += 1

        break if processed >= limit
      end
    end

    def print_jobs(limit: 100)
      processed = 0

      Sidekiq::Queue.new(self).each do |job|
        puts "#{self}: args=#{job.args}"

        processed += 1
        break if processed >= limit
      end
    end
  end
end
