class CallCreateDirectMessageEventCount < ::Egotter::SortedSet

  def initialize
    super(Redis.client)

    @ttl = 1.day
    @key = "#{Rails.env}:#{self.class}:#{@ttl}:any_ids"
  end

  def increment
    add(Time.zone.now.to_f)
  end

  def raised
    key = "#{Rails.env}:#{self.class}:raised"
    Redis.client.setex(key, 1.hour, '1')
  end

  def raised?
    key = "#{Rails.env}:#{self.class}:raised"
    Redis.client.exists(key)
  end

  def rate_limited?
    size > 15000 || raised?
  end

  class << self
    def rate_limited?
      new.rate_limited?
    end
  end
end
