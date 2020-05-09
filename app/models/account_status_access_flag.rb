class AccountStatusAccessFlag < ::Egotter::SortedSet

  def initialize
    @redis = Redis.client

    @ttl = 5.minutes
    @key = "#{Rails.env}:#{self.class}:#{@ttl}:any_ids"
  end

  def accessed(user_id)
    add(user_id)
  end

  def accessed?(user_id)
    exists?(user_id)
  end
end
