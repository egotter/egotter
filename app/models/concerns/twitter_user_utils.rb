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
      @persisted_friend_uids = fetch_friend_uids
    end
  end

  def follower_uids
    if new_record?
      raise "The ##{__method__} should not be called if the records is not persisted"
    end

    if instance_variable_defined?(:@persisted_follower_uids)
      @persisted_follower_uids
    else
      @persisted_follower_uids = fetch_follower_uids
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
    }
  end

  private

  def fetch_friend_uids
    fetch_uids(:friend_uids, InMemory::TwitterUser, Efs::TwitterUser, S3::Friendship)
  end

  def fetch_follower_uids
    fetch_uids(:follower_uids, InMemory::TwitterUser, Efs::TwitterUser, S3::Followership)
  end

  def fetch_uids(method_name, memory_class, efs_class, s3_class)
    wrapper = nil
    start = Time.zone.now

    wrapper = memory_class.find_by(id) if InMemory.enabled? && InMemory.cache_alive?(created_at)
    wrapper = efs_class.find_by(id) if wrapper.nil? && Efs.enabled?
    wrapper = s3_class.find_by(twitter_user_id: id) if wrapper.nil?

    time = "elapsed=#{sprintf("%.3f sec", Time.zone.now - created_at)} duration=#{sprintf("%.3f sec", Time.zone.now - start)}"
    if wrapper.nil?
      logger.warn "#{__method__}: Failed twitter_user_id=#{id} uid=#{uid} method=#{method_name} #{time}"
      logger.info caller.join("\n")
      []
    else
      logger.info "#{__method__}: Found twitter_user_id=#{id} uid=#{uid} method=#{method_name} wrapper=#{wrapper.class} #{time}"
      wrapper.send(method_name)
    end
  end
end
