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

  def friend_uids
    if new_record?
      raise "The ##{__method__} should not be called if the records is not persisted"
    end

    if instance_variable_defined?(:@persisted_friend_uids)
      @persisted_friend_uids
    else
      @persisted_friend_uids = fetch_uids(:friend_uids, InMemory::TwitterUser, Efs::TwitterUser, S3::Friendship)
    end
  end

  def follower_uids
    if new_record?
      raise "The ##{__method__} should not be called if the records is not persisted"
    end

    if instance_variable_defined?(:@persisted_follower_uids)
      @persisted_follower_uids
    else
      @persisted_follower_uids = fetch_uids(:follower_uids, InMemory::TwitterUser, Efs::TwitterUser, S3::Followership)
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
  end

  def to_summary
    {
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

  def fetch_uids(method_name, memory_class, efs_class, s3_class)
    data = nil
    exceptions = []

    begin
      data = memory_class.find_by(id) if InMemory.enabled? && InMemory.cache_alive?(created_at)
    rescue => e
      exceptions << e
    end

    begin
      data = efs_class.find_by(id) if data.nil? && Efs.enabled?
    rescue => e
      exceptions << e
    end

    begin
      data = s3_class.find_by(twitter_user_id: id) if data.nil?
    rescue => e
      exceptions << e
    end

    if data.nil?
      Airbag.info "Fetching data failed. method=#{method_name} id=#{id} screen_name=#{screen_name} created_at=#{created_at.to_s(:db)} exceptions=#{exceptions.inspect}"
      Airbag.info caller.join("\n")
      # TODO Import collect uids or delete this record
      []
    else
      data.send(method_name) || []
    end
  end
end
