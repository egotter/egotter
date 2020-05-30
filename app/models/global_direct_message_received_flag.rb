class GlobalDirectMessageReceivedFlag < ::Egotter::AsyncSortedSet

  def initialize
    super(Redis.client)

    @ttl = 1.days
    @key = "#{Rails.env}:#{self.class}:#{@ttl}:any_ids"
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
