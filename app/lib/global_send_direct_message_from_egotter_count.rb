class GlobalSendDirectMessageFromEgotterCount < ::Egotter::AsyncSortedSet

  def initialize
    super(Redis.client)

    @ttl = 1.day
    @key = "#{Rails.env}:#{self.class}:#{@ttl}:any_ids"
  end

  def increment
    add(Time.zone.now.to_f)
  end

  def soft_limited?
    size > 900
  end

  def hard_limited?
    size > 1000
  end
end
