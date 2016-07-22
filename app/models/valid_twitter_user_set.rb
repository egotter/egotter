class ValidTwitterUserSet < TwitterUserSet
  def self.key
    @@key ||= 'valid_twitter_user'
  end

  def self.ttl
    @@ttl ||= 1.hour.to_i
  end
end