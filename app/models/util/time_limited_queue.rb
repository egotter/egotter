class Util::TimeLimitedQueue < Util::OriginalSortedSet
  def initialize(worker_class, ttl = nil)
    super(Redis.client)

    if ttl
      @key = "#{self.class}:#{worker_class}:#{ttl}:any_ids"
      @ttl = ttl
    else
      @key = "#{self.class}:#{worker_class}:any_ids"
    end
  end
end
