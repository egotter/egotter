class WorkerCanceller
  # include Sidekiq::Worker

  def perform(*args)
    delayed_works = []
    workers = Sidekiq::Workers.new

    workers.each do |pid, tid, work|
      run_at = Time.zone.at(work['run_at'])
      if run_at < 1.hour.ago
        delayed_works << {queue: work['queue'], run_at: run_at, jid: work['payload']['jid']}
      end
    end

    delayed_works.each do |work|
      self.class.cancel!(work[:jid])
    end
  end

  class << self
    def cancel!(jid)
      Sidekiq.redis { |c| c.setex("cancelled-#{jid}", 86400, 1) }
    end
  end
end
