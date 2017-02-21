require 'active_support/concern'

module Concerns::TwitterUser::Api
  extend ActiveSupport::Concern

  included do
  end

  def dummy_client
    ApiClient.dummy_instance
  end

  def calc_one_sided_friend_uids
    friend_uids - follower_uids
  end

  def one_sided_friend_uids
    one_sided_friendships.pluck(:friend_uid)
  end

  def calc_one_sided_follower_uids
    follower_uids - friend_uids
  end

  def one_sided_follower_uids
    one_sided_followerships.pluck(:follower_uid)
  end

  def calc_mutual_friend_uids
    friend_uids & follower_uids
  end

  def mutual_friend_uids
    mutual_friendships.pluck(:friend_uid)
  end

  def common_friend_uids(other)
    friend_uids & other.friend_uids
  end

  def common_friends(other)
    uids = common_friend_uids(other)
    uids.empty? ? [] : friends.where(uid: uids)
  end

  def common_follower_uids(other)
    follower_uids & other.follower_uids
  end

  def common_followers(other)
    uids = common_follower_uids(other)
    uids.empty? ? [] : followers.where(uid: uids)
  end

  def conversations(other)
    statuses1 = statuses.select { |status| !status.text.start_with?('RT') && status.text.include?(other.mention_name) }
    statuses2 = other.statuses.select { |status| !status.text.start_with?('RT') && status.text.include?(mention_name) }
    (statuses1 + statuses2).sort_by { |status| -status.tweeted_at.to_i }
  end

  def new_removing_uids(newer)
    friend_uids - newer.friend_uids
  end

  def new_removing
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return friends.none if newer.nil? || older.nil? || newer.friends_size == 0
    uids = older.new_removing_uids(newer)
    uids.empty? ? friends.none : older.friends.where(uid: uids)
  end

  def calc_removing_uids
    TwitterUser.with_friends.where(uid: uid).order(created_at: :asc).each_cons(2).map do |older, newer|
      next if newer.nil? || older.nil? || newer.friends_size == 0
      older.new_removing_uids(newer)
    end.compact.flatten.reverse
  end

  def removing_uids
    unfriendships.pluck(:friend_uid)
  end

  def removing
    unfriends
  end

  def new_removed_uids(newer)
    follower_uids - newer.follower_uids
  end

  def new_removed
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return followers.none if newer.nil? || older.nil? || newer.followers_size == 0
    uids = older.new_removed_uids(newer)
    uids.empty? ? followers.none : older.followers.where(uid: uids)
  end

  def calc_removed_uids
    TwitterUser.with_friends.where(uid: uid).order(created_at: :asc).each_cons(2).map do |older, newer|
      next if newer.nil? || older.nil? || newer.followers_size == 0
      older.new_removed_uids(newer)
    end.compact.flatten.reverse
  end

  def removed_uids
    unfollowerships.pluck(:follower_uid)
  end

  def removed
    unfollowers
  end

  def blocking_or_blocked_uids
    removing_uids & removed_uids
  end

  def blocking_or_blocked
    uids = blocking_or_blocked_uids
    uids.empty? ? removing.none : removing.where(uid: uids)
  end

  def new_friend_uids
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return [] if newer.nil?
    return newer.friend_uids.take(8) if older.nil? || older.friends_size == 0
    uids = newer.friend_uids - older.friend_uids
    uids.empty? ? newer.friend_uids.take(8) : uids
  end

  def new_friends
    uids = new_friend_uids
    return friends.none if uids.empty?
    users = TwitterDB::User.where(uid: uids).index_by(&:uid)
    uids.map { |uid| users[uid] }.compact
  end

  def new_follower_uids
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return [] if newer.nil?
    return newer.follower_uids.take(8) if older.nil? || older.followers_size == 0
    uids = newer.follower_uids - older.follower_uids
    uids.empty? ? newer.follower_uids.take(8) : uids
  end

  def new_followers
    uids = new_follower_uids
    return followers.none if uids.empty?
    users = TwitterDB::User.where(uid: uids).index_by(&:uid)
    uids.map { |uid| users[uid] }.compact
  end

  def replying_uids(uniq: true)
    uids = statuses.select { |status| !status.text.start_with? 'RT' }.map { |status| status&.entities&.user_mentions&.map { |obj| obj['id'] } }&.flatten.compact
    uniq ? uids.uniq : uids
  end

  def replying(uniq: true)
    # statuses.map { |status| status.entities&.user_mentions&.map { |obj| obj['id'] } }&.flatten.compact
    # statuses.map { |status| $1 if status.text.match /^(?:\.)?@(\w+)( |\W)/ }.compact

    uids = replying_uids(uniq: uniq)
    users = TwitterDB::User.where(uid: uids).index_by(&:uid)
    uids.map { |uid| users[uid] }.compact
  end

  def reply_tweets(login_user: nil)
    if login_user&.uid&.to_i == uid.to_i
      mentions
    elsif search_results.any?
      search_results.select { |status| !status.text.start_with?('RT') && status.text.include?(mention_name) }
    else
      []
    end
  end

  def replied_uids(uniq: true, login_user: nil)
    uids = reply_tweets(login_user: login_user).map { |tweet| tweet.user&.id }.compact
    uniq ? uids.uniq : uids
  end

  def replied(uniq: true, login_user: nil)
    users = reply_tweets(login_user: login_user).map(&:user).compact
    users.uniq!(&:id) if uniq
    users.each { |user| user.uid = user.id }
  end

  def replying_and_replied_uids(uniq: true, login_user: nil)
    replying_uids(uniq: uniq) & replied_uids(uniq: uniq, login_user: login_user)
  end

  def replying_and_replied(uniq: true, login_user: nil)
    uids = replying_and_replied_uids(uniq: uniq, login_user: login_user)
    users = (replying(uniq: uniq) + replied(uniq: uniq, login_user: login_user)).index_by(&:uid)
    uids.map { |uid| users[uid] }.compact
  end

  def favoriting_uids(uniq: true, min: 0)
    uids = favorites.map { |fav| fav&.user&.id }.each_with_object(Hash.new(0)) { |uid, memo| memo[uid] += 1 }.sort_by { |_, v| -v }.map(&:first)
    uniq ? uids.uniq : uids
  end

  def favoriting(uniq: true, min: 0)
    uids = favoriting_uids(uniq: uniq, min: min)
    users = favorites.map(&:user).index_by(&:id)
    users = uids.map { |uid| users[uid] }
    users.uniq!(&:id) if uniq
    users.each { |user| user.uid = user.id }
  end

  def close_friend_uids(uniq: false, min: 1, limit: 50, login_user: nil)
    uids = replying_uids(uniq: uniq) + replied_uids(uniq: uniq, login_user: login_user) + favoriting_uids(uniq: uniq, min: min)
    uids.each_with_object(Hash.new(0)) { |uid, memo| memo[uid] += 1 }.sort_by { |_, v| -v }.take(limit).map(&:first)
  end

  def close_friends(uniq: false, min: 1, limit: 50, login_user: nil)
    uids = close_friend_uids(uniq: uniq, min: min, limit: limit, login_user: login_user)
    users = (replying(uniq: uniq) + replied(uniq: uniq, login_user: login_user) + favoriting(uniq: uniq, min: min)).uniq(&:uid).index_by(&:uid)
    users = uids.map { |uid| users[uid] }.compact
    users.each { |user| user.uid = user.id }
  end

  def inactive_friend_uids
    inactive_friends.map(&:uid)
  end

  def inactive_friends
    two_weeks_ago = 2.weeks.ago
    friends.select do |friend|
      begin
        friend&.status&.created_at && Time.parse(friend&.status&.created_at) < two_weeks_ago
      rescue => e
        logger.warn "#{__method__}: #{e.class} #{e.message} #{uid} #{screen_name} [#{friend&.status&.created_at}] #{friend.uid} #{friend.screen_name}"
        false
      end
    end
  end

  def inactive_follower_uids
    inactive_followers.map(&:uid)
  end

  def inactive_followers
    two_weeks_ago = 2.weeks.ago
    followers.select do |follower|
      begin
        follower&.status&.created_at && Time.parse(follower.status.created_at) < two_weeks_ago
      rescue => e
        logger.warn "#{__method__}: #{e.class} #{e.message} #{uid} #{screen_name} [#{follower&.status&.created_at}] #{follower.uid} #{follower.screen_name}"
        false
      end
    end
  end

  def inactive_mutual_friend_uids
    inactive_mutual_friends.map(&:uid)
  end

  def inactive_mutual_friends
    two_weeks_ago = 2.weeks.ago
    mutual_friends.select do |friend|
      begin
        friend&.status&.created_at && Time.parse(friend&.status&.created_at) < two_weeks_ago
      rescue => e
        logger.warn "#{__method__}: #{e.class} #{e.message} #{uid} #{screen_name} [#{friend&.status&.created_at}] #{friend.uid} #{friend.screen_name}"
        false
      end
    end
  end

  def clusters_belong_to
    dummy_client.tweet_clusters(statuses, limit: 100)
  end

  def usage_stats_graph
    client.usage_stats(extract_time_from_tweets(statuses), day_names: I18n.t('date.abbr_day_names'))
  end

  def frequency_distribution(words)
    words.map { |word, count| {name: word, y: count} }
  end

  def clusters_belong_to_cloud
    clusters_belong_to.map.with_index { |(word, count), i| {text: word, size: count, group: i % 3} }
  end

  def clusters_belong_to_frequency_distribution
    frequency_distribution(clusters_belong_to.to_a.slice(0, 10))
  end

  def percentile_index(ary, percentile = 0.0)
    ((ary.length * percentile).ceil) - 1
  end

  def hashtags
    statuses.select { |s| s.hashtags? }.map { |s| s.hashtags }.flatten.
      map { |h| "##{h}" }.each_with_object(Hash.new(0)) { |hashtag, memo| memo[hashtag] += 1 }.
      sort_by { |h, c| [-c, -h.size] }.to_h
  end

  def usage_stats(day_count: 365)
    return [nil, nil, nil, nil, nil] if statuses.empty?
    client.usage_stats(extract_time_from_tweets(statuses, day_count: day_count), day_names: I18n.t('date.abbr_day_names'))
  end

  def statuses_breakdown
    tweets = statuses
    if tweets.empty?
      {
        mentions: 0.0,
        media: 0.0,
        urls: 0.0,
        hashtags: 0.0,
        location: 0.0
      }
    else
      tweets_size = tweets.size
      {
        mentions: tweets.select { |s| s.mentions? }.size.to_f / tweets_size * 100,
        media: tweets.select { |s| s.media? }.size.to_f / tweets_size * 100,
        urls: tweets.select { |s| s.urls? }.size.to_f / tweets_size * 100,
        hashtags: tweets.select { |s| s.hashtags? }.size.to_f / tweets_size * 100,
        location: tweets.select { |s| s.location? }.size.to_f / tweets_size * 100
      }
    end
  end

  private

  def extract_time_from_tweets(tweets, day_count: 365)
    past = day_count.days.ago
    tweets.map { |s| s.tweeted_at }.select { |t| t > past }
  end
end
