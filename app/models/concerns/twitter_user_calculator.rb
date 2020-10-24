require 'active_support/concern'

module TwitterUserCalculator
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
  end

  def calc_uids_for(klass, login_user: nil)
    if klass == S3::CloseFriendship
      calc_close_friend_uids(login_user: login_user)
    elsif klass == S3::FavoriteFriendship
      calc_favorite_uids
    elsif klass == S3::OneSidedFriendship
      calc_one_sided_friend_uids
    elsif klass == S3::OneSidedFollowership
      calc_one_sided_follower_uids
    elsif klass == S3::MutualFriendship
      calc_mutual_friend_uids
    elsif klass == S3::InactiveFriendship
      calc_inactive_friend_uids
    elsif klass == S3::InactiveFollowership
      calc_inactive_follower_uids
    elsif klass == S3::InactiveMutualFriendship
      calc_inactive_mutual_friend_uids
    elsif klass == S3::Unfriendship
      calc_unfriend_uids
    elsif klass == S3::Unfollowership
      calc_unfollower_uids
    elsif klass == S3::MutualUnfriendship
      calc_mutual_unfriend_uids
    else
      raise "#{__method__} Invalid klass is passed klass=#{klass}"
    end
  end

  def update_counter_cache_for(klass, count)
    if klass == S3::OneSidedFriendship
      update(one_sided_friends_size: count)
    elsif klass == S3::OneSidedFollowership
      update(one_sided_followers_size: count)
    elsif klass == S3::MutualFriendship
      update(mutual_friends_size: count)
    elsif klass == S3::Unfriendship
      update(unfriends_size: count)
    elsif klass == S3::Unfollowership
      update(unfollowers_size: count)
    elsif klass == S3::MutualUnfriendship
      update(mutual_unfriends_size: count)
    else
      # Do nothing
    end
  end

  def calc_statuses_interval
    tweets = status_tweets.map { |t| t.tweeted_at.to_i }.sort_by { |t| -t }.take(100)
    tweets = tweets.slice(0, tweets.size - 1) if tweets.size.odd?
    return 0.0 if tweets.empty?
    times = tweets.each_slice(2).map { |t1, t2| t1 - t2 }
    times.sum / times.size
  rescue
    0.0
  end

  def calc_one_sided_friend_uids
    friend_uids - follower_uids
  end

  def calc_one_sided_follower_uids
    follower_uids - friend_uids
  end

  def calc_mutual_friend_uids
    friend_uids & follower_uids
  end

  def calc_favorite_uids
    favorite_tweets.map { |fav| fav&.user&.id }.compact
  end

  def calc_favorite_friend_uids(uniq: true)
    uids = calc_favorite_uids
    uniq ? sort_by_count_desc(uids) : uids
  end

  def calc_close_friend_uids(login_user:)
    uids = replying_uids(uniq: false) + replied_uids(uniq: false, login_user: login_user) + calc_favorite_friend_uids(uniq: false)
    sort_by_count_desc(uids).take(100)
  end

  def calc_inactive_friend_uids
    friends(inactive: true).map(&:uid)
  end

  def calc_inactive_follower_uids
    followers(inactive: true).map(&:uid)
  end

  def calc_inactive_mutual_friend_uids
    mutual_friends(inactive: true).map(&:uid)
  end

  def calc_mutual_unfriend_uids
    (calc_unfriend_uids & calc_unfollower_uids | fetch_blocked_uids).uniq
  end

  def unfriends_builder
    @unfriends_builder ||= UnfriendsBuilder.new(uid, end_date: created_at)
  end

  def calc_unfriend_uids
    unfriends_builder.unfriends.flatten
  end

  def calc_unfollower_uids
    unfriends_builder.unfollowers.flatten
  end

  private

  def fetch_blocked_uids
    BlockingRelationship.where(to_uid: uid).select('distinct form_uid').limit(1000).pluck(:from_uid)
  end

  def sort_by_count_desc(ids)
    ids.each_with_object(Hash.new(0)) { |id, memo| memo[id] += 1 }.sort_by { |_, v| -v }.map(&:first)
  end
end
