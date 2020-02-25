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

  def raised_ttl
    key = "#{Rails.env}:#{self.class}:raised"
    Redis.client.ttl(key)
  end

  def raised?
    key = "#{Rails.env}:#{self.class}:raised"
    Redis.client.exists(key)
  end

  def rate_limited?
    size > 15000 || raised?
  end

  class << self
    %i(
        increment
        raised
        raised_ttl
        raised?
        rate_limited?
    ).each do |method_name|
      define_method(method_name) do
        new.send(method_name)
      end
    end
  end
end
