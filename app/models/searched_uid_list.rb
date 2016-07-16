# Sorted Set
class SearchedUidList < UidList
  def self.key
    @@key ||= 'background_search_worker:searched_uids'
  end

  def self.ttl
    @@ttl ||= Rails.configuration.x.constants['background_search_worker_recently_searched']
  end
end