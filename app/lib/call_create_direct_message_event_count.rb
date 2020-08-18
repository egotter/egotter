class CallCreateDirectMessageEventCount < ::Egotter::AsyncSortedSet

  def initialize
    super(Redis.client)

    @ttl = 1.day
    @key = "#{Rails.env}:#{self.class}:#{@ttl}:any_ids"
  end

  def increment
    add(Time.zone.now.to_f)
  end

  def soft_limited?
    size > 14000
  end

  def hard_limited?
    size > 15000
  end
end
