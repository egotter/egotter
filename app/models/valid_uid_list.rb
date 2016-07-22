# Sorted Set
class ValidUidList < UidList
  def self.key
    @@key ||= 'validation:valid_uids'
  end

  def self.ttl
    @@ttl ||= 1.hour.to_i
  end
end