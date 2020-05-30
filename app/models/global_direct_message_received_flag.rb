class GlobalDirectMessageReceivedFlag < ::Egotter::AsyncSortedSet

  def initialize
    @redis = Redis.client

    @ttl = 1.days
    @key = "#{Rails.env}:#{self.class}:#{@ttl}:any_ids"

    @async_flag = true
  end

  def sync_mode
    @async_flag = false
    self
  end

  def received(uid)
    add(uid)
  end

  def received?(uid)
    exists?(uid)
  end

  def remaining(uid)
    ttl(uid)
  end
end
