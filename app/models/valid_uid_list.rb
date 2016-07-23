# Sorted Set
class ValidUidList < UidList
  def self.key
    @@key ||= 'validation:valid_uids'
  end

  def self.ttl
    @@ttl ||= 10.minutes.to_i
  end
end