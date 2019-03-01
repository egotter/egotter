class RunningQueue < Util::OriginalSortedSet
  def initialize(worker_class)
    @@key = "#{self.class}:#{worker_class}:uids"
    super(Redis.client)
  end

  def self.key
    @@key
  end

  def self.ttl
    @@ttl ||= (Rails.env.production? ? 1.hour : 10.minutes)
  end
end