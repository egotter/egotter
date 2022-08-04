require 'active_support/concern'

module TwitterUserUtils
  extend ActiveSupport::Concern

  # Reason1: too many friends
  # Reason2: near zero friends
  def no_need_to_import_friendships?
    friends_size == 0 && followers_size == 0
  end

  def too_little_friends?
    friends_count == 0 && followers_count == 0 && friends_size == 0 && followers_size == 0
  end

  def friend_uids(exception: false)
    if new_record?
      raise "The ##{__method__} should not be called if the records is not persisted"
    end

    if instance_variable_defined?(:@persisted_friend_uids)
      @persisted_friend_uids
    else
      @persisted_friend_uids = fetch_uids(:friend_uids, S3::Friendship, exception)
    end
  end

  def follower_uids(exception: false)
    if new_record?
      raise "The ##{__method__} should not be called if the records is not persisted"
    end

    if instance_variable_defined?(:@persisted_follower_uids)
      @persisted_follower_uids
    else
      @persisted_follower_uids = fetch_uids(:follower_uids, S3::Followership, exception)
    end
  end

  CREATE_RECORD_INTERVAL = 30.minutes

  # TODO Replace with class method
  def too_short_create_interval?
    CREATE_RECORD_INTERVAL.seconds.ago < created_at
  end

  class_methods do
    def too_short_create_interval?(uid)
      exists?(uid: uid, created_at: CREATE_RECORD_INTERVAL.ago..Time.zone.now)
    end

    def where_mod(n1, n2)
      num = 100 * n1 + n2
      records = order(created_at: :desc).select(:id, :uid).where('created_at > ?', 1.day.ago)
      ids = records.uniq(&:uid).select { |r| r.uid % num == 0 }
      where(id: ids)
    end
  end

  def to_summary
    {
        friends: friends_size || friend_uids.size,
        followers: followers_size || follower_uids.size,
        one_sided_friends: one_sided_friends_size || one_sided_friendships.size,
        one_sided_followers: one_sided_followers_size || one_sided_followerships.size,
        mutual_friends: mutual_friends_size || mutual_friendships.size,
        unfriends: unfriends_size,
        unfollowers: unfollowers_size,
        mutual_unfriends: mutual_unfriends_size || mutual_unfriendships.size,
        blockers: blockers_size,
        muters: muters_size,
        inactive_friends: inactive_friends_size || inactive_friendships.size,
        inactive_followers: inactive_followers_size || inactive_followerships.size,
    }
  end

  private

  def fetch_uids(method_name, s3_class, exception)
    data = nil
    errors = []
    source = nil
    start = Time.zone.now

    begin
      if InMemory.enabled? && InMemory.cache_alive?(created_at)
        data = InMemory::TwitterUser.find_by(id)
        source = 'memory'
      end
    rescue => e
      raise if exception
      errors << e
    end

    begin
      if data.nil? && Efs.enabled?
        data = Efs::TwitterUser.find_by(id)
        source = 'efs'
      end
    rescue => e
      raise if exception
      errors << e
    end

    begin
      if data.nil?
        data = s3_class.find_by(twitter_user_id: id)
        source = 's3'
      end
    rescue => e
      raise if exception
      errors << e
    end

    if data.nil?
      Airbag.info "Fetching #{method_name} failed", twitter_user_id: id, uid: uid, created_at: created_at.to_s(:db), exceptions: errors.inspect, caller: caller
      # TODO Import collect uids or delete this record
      []
    else
      Airbag.info "Fetching #{method_name} succeeded", twitter_user_id: id, uid: uid, source: source, elapsed: (Time.zone.now - start) if Rails.env.development?
      ArrayWithSource.new(data.send(method_name) || [], source)
    end
  end

  class ArrayWithSource < ::Array
    attr_reader :source

    def initialize(ary, source)
      super(ary)
      @source = source
    end
  end
end
