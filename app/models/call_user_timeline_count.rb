class CallUserTimelineCount < ::Egotter::SortedSet

  def initialize
    super(Redis.client)

    @ttl = 1.day
    @key = "#{Rails.env}:#{self.class}:#{@ttl}:any_ids"
  end

  def increment
    add(Time.zone.now.to_f)
  end

  def rate_limited?
    size > 100_000
  end
end
