require 'active_support/concern'

module TwitterUserCalculator
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
    def calc_total_new_friend_uids(users)
      return [] if users.size <= 1
      users.sort_by(&:created_at).each_cons(2).map { |prev, cur| cur.calc_new_friend_uids(prev) }.flatten.reverse
    end

    def calc_total_new_follower_uids(users)
      return [] if users.size <= 1
      users.sort_by(&:created_at).each_cons(2).map { |prev, cur| cur.calc_new_follower_uids(prev) }.flatten.reverse
    end

    def calc_total_new_unfriend_uids(users)
      return [] if users.size <= 1
      users.sort_by(&:created_at).each_cons(2).map { |prev, cur| cur.calc_new_unfriend_uids(prev) }.flatten.reverse
    end

    def calc_total_new_unfollower_uids(users)
      return [] if users.size <= 1
      users.sort_by(&:created_at).each_cons(2).map { |prev, cur| cur.calc_new_unfollower_uids(prev) }.flatten.reverse
    end
  end

  def calc_and_import(klass)
    uids = calc_uids_for(klass)
    klass.import_from!(uid, uids)
    update_counter_cache_for(klass, uids.size)
    uids
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
      calc_inactive_friend_uids(threads: 2)
    elsif klass == S3::InactiveFollowership
      calc_inactive_follower_uids(threads: 2)
    elsif klass == S3::InactiveMutualFriendship
      calc_inactive_mutual_friend_uids(threads: 2)
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
    elsif klass == S3::InactiveFriendship
      update(inactive_friends_size: count)
    elsif klass == S3::InactiveFollowership
      update(inactive_followers_size: count)
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

  def calc_follow_back_rate
    numerator = mutual_friendships.size
    # Use #followers_count instead of #follower_uids.size to reduce calls to the external API
    denominator = followers_count
    (numerator == 0 || denominator <= 0) ? 0.0 : numerator.to_f / denominator
  rescue
    0.0
  end

  def calc_reverse_follow_back_rate
    numerator = mutual_friendships.size
    # Use #friends_count instead of #friend_uids.size to reduce calls to the external API
    denominator = friends_count
    (numerator == 0 || denominator <= 0) ? 0.0 : numerator.to_f / denominator
  rescue
    0.0
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

  def calc_inactive_friend_uids(slice: 1000, threads: 0)
    calc_inactive_friend_uids!(slice: slice, threads: threads)
  rescue ThreadError => e
    Airbag.warn 'calc_inactive_friend_uids: ThreadError is detected and retry without threads', exception: e.inspect, current: Thread.current.inspect, main: Thread.main.inspect, backtrace: e.backtrace
    calc_inactive_friend_uids!(slice: slice, threads: 0)
  end

  def calc_inactive_friend_uids!(slice: 1000, threads: 0)
    fetch_inactive_uids(friend_uids, slice, threads)
  end

  def calc_inactive_follower_uids(slice: 1000, threads: 0)
    calc_inactive_follower_uids!(slice: slice, threads: threads)
  rescue ThreadError => e
    Airbag.warn 'calc_inactive_follower_uids: ThreadError is detected and retry without threads', exception: e.inspect, current: Thread.current.inspect, main: Thread.main.inspect, backtrace: e.backtrace
    calc_inactive_follower_uids!(slice: slice, threads: 0)
  end

  def calc_inactive_follower_uids!(slice: 1000, threads: 0)
    fetch_inactive_uids(follower_uids, slice, threads)
  end

  def calc_inactive_mutual_friend_uids(slice: 1000, threads: 0)
    calc_inactive_mutual_friend_uids!(slice: slice, threads: threads)
  rescue ThreadError => e
    Airbag.warn 'calc_inactive_mutual_friend_uids: ThreadError is detected and retry without threads', exception: e.inspect, current: Thread.current.inspect, main: Thread.main.inspect, backtrace: e.backtrace
    calc_inactive_mutual_friend_uids!(slice: slice, threads: 0)
  end

  def calc_inactive_mutual_friend_uids!(slice: 1000, threads: 0)
    fetch_inactive_uids(mutual_friend_uids, slice, threads)
  end

  def fetch_inactive_uids(uids, slice, threads)
    if threads > 0 && uids.size > slice
      fetch_inactive_uids_in_threads(uids, slice, threads)
    else
      fetch_inactive_uids_direct(uids, slice)
    end
  end

  def fetch_inactive_uids_in_threads(uids, slice, threads)
    uids.each_slice(slice * threads).map do |group|
      group.each_slice(slice).map do |task|
        Thread.new(task) do |t|
          ActiveRecord::Base.connection_pool.with_connection do
            TwitterDB::User.where(uid: t).inactive_2weeks.order_by_field(t).pluck(:uid)
          end
        end
      end.map(&:value)
    end.flatten
  end

  def fetch_inactive_uids_direct(uids, slice)
    uids.each_slice(slice).map do |group|
      TwitterDB::User.where(uid: group).inactive_2weeks.order_by_field(group).pluck(:uid)
    end.flatten
  end

  def calc_unfriend_uids(limit = 50)
    self.class.calc_total_new_unfriend_uids(unfriends_target(limit))
  end

  def calc_unfollower_uids(limit = 50)
    self.class.calc_total_new_unfollower_uids(unfriends_target(limit))
  end

  def calc_mutual_unfriend_uids
    (calc_unfriend_uids & calc_unfollower_uids).uniq
  end

  def calc_new_friend_uids(record = nil)
    record ||= previous_version
    record ? friend_uids - record.friend_uids : []
  rescue => e
    Airbag.info "#{__method__}: #{e.inspect} twitter_user_id=#{id} uid=#{uid}"
    []
  end

  def calc_new_follower_uids(record = nil)
    record ||= previous_version
    record ? follower_uids - record.follower_uids : []
  rescue => e
    Airbag.info "#{__method__}: #{e.inspect} twitter_user_id=#{id} uid=#{uid}"
    []
  end

  def calc_new_unfriend_uids(record = nil)
    record ||= previous_version
    record ? record.friend_uids - friend_uids : []
  rescue => e
    Airbag.info "#{__method__}: #{e.inspect} twitter_user_id=#{id} uid=#{uid}"
    []
  end

  def calc_new_unfollower_uids(record = nil)
    record ||= previous_version
    record ? record.follower_uids - follower_uids : []
  rescue => e
    Airbag.info "#{__method__}: #{e.inspect} twitter_user_id=#{id} uid=#{uid}"
    []
  end

  def previous_version
    if instance_variable_defined?(:@previous_version)
      @previous_version
    else
      @previous_version = TwitterUser.where(uid: uid).where('created_at < ?', created_at).order(created_at: :desc).first
    end
  end

  # For debugging
  def next_version
    TwitterUser.where(uid: uid).where('created_at > ?', created_at).order(created_at: :asc).first
  end

  private

  def unfriends_target(limit = 50)
    # Want to decrease limit
    @unfriends_target ||= TwitterUser.select(:id, :uid, :screen_name, :created_at).
        creation_completed.
        where(uid: uid).
        where('created_at <= ?', created_at).
        order(created_at: :desc).
        limit(limit).
        reverse
  end

  def sort_by_count_desc(ids)
    ids.each_with_object(Hash.new(0)) { |id, memo| memo[id] += 1 }.sort_by { |_, v| -v }.map(&:first)
  end
end
