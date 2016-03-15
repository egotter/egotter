class SidekiqHandler < ActiveRecord::Base
  def self.queue
    Sidekiq::Queue.new('egotter')
  end

  def self.latency
    queue.latency
  end

  def self.delay_occurs?
    latency > 5
  end

  def self.stats
    Sidekiq::Stats.new
  end

  def self.process_set
    Sidekiq::ProcessSet.new
  end

  def self.workers
    Sidekiq::Workers.new
  end
end
