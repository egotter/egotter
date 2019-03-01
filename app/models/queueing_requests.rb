class QueueingRequests < Util::OriginalSortedSet
  def initialize(worker_class)
    super(Redis.client)
    @key = "#{self.class}:#{worker_class}:any_ids"
  end
end
