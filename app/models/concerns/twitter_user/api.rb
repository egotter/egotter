require 'active_support/concern'

module Concerns::TwitterUser::Api
  extend ActiveSupport::Concern

  included do
  end

  def dummy_client
    ApiClient.dummy_instance
  end

  def one_sided_friend_uids
    friend_uids - follower_uids
  end

  def one_sided_friends
    uids = one_sided_friend_uids
    uids.empty? ? [] : friends.where(uid: uids)
  end

  def one_sided_follower_uids
    follower_uids - friend_uids
  end

  def one_sided_followers
    uids = one_sided_follower_uids
    uids.empty? ? [] : followers.where(uid: uids)
  end

  def mutual_friend_uids
    friend_uids & follower_uids
  end

  def mutual_friends
    uids = mutual_friend_uids
    uids.empty? ? [] : friends.where(uid: uids)
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
    return [] unless self.class.many?(uid)
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return [] if newer.nil? || older.nil? || newer.friends_size == 0
    uids = older.new_removing_uids(newer)
    uids.empty? ? [] : older.friends.where(uid: uids)
  end

  # TODO experimental
  def calc_removing_uids
    return [] unless self.class.many?(uid)
    TwitterUser.with_friends.where(uid: uid).order(created_at: :asc).each_cons(2).map do |older, newer|
      next if newer.nil? || older.nil? || newer.friends_size == 0
      older.new_removing_uids(newer)
    end.compact.flatten.reverse
  end

  def calc_removing
    return [] unless self.class.many?(uid)
    TwitterUser.with_friends.where(uid: uid).order(created_at: :asc).each_cons(2).map do |older, newer|
      next if newer.nil? || older.nil? || newer.friends_size == 0
      uids = older.new_removing_uids(newer)
      uids.empty? ? [] : older.friends.where(uid: uids)
    end.compact.flatten.reverse
  end

  def removing_uids
    unfriendships.any? ? unfriendships.pluck(:friend_uid) : calc_removing_uids
  end

  def removing
    unfriends.any? ? unfriends : calc_removing
  end

  def new_removed_uids(newer)
    follower_uids - newer.follower_uids
  end

  def new_removed
    return [] unless self.class.many?(uid)
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return [] if newer.nil? || older.nil? || newer.followers_size == 0
    uids = older.new_removed_uids(newer)
    uids.empty? ? [] : older.followers.where(uid: uids)
  end

  # TODO experimental
  def calc_removed_uids
    return [] unless self.class.many?(uid)
    TwitterUser.with_friends.where(uid: uid).order(created_at: :asc).each_cons(2).map do |older, newer|
      next if newer.nil? || older.nil? || newer.followers_size == 0
      older.new_removed_uids(newer)
    end.compact.flatten.reverse
  end

  def calc_removed
    return [] unless self.class.many?(uid)
    TwitterUser.with_friends.where(uid: uid).order(created_at: :asc).each_cons(2).map do |older, newer|
      next if newer.nil? || older.nil? || newer.followers_size == 0
      uids = older.new_removed_uids(newer)
      uids.empty? ? [] : older.followers.where(uid: uids)
    end.compact.flatten.reverse
  end

  def removed_uids
    unfollowerships.any? ? unfollowerships.pluck(:follower_uid) : calc_removed_uids
  end

  def removed
    unfollowers.any? ? unfollowers : calc_removed
  end

  def new_friend_uids
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return [] if newer.nil? || older.nil? || older.friends_size == 0
    newer.friend_uids - older.friend_uids
  end

  def new_friends
    uids = new_friend_uids
    return [] if uids.empty?
    users = TwitterDB::User.where(uid: uids).index_by(&:uid)
    uids.map { |uid| users[uid] }.compact
  end

  def new_follower_uids
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return [] if newer.nil? || older.nil? || older.followers_size == 0
    newer.follower_uids - older.follower_uids
  end

  def new_followers
    uids = new_follower_uids
    return [] if uids.empty?
    users = TwitterDB::User.where(uid: uids).index_by(&:uid)
    uids.map { |uid| users[uid] }.compact
  end

  def blocking_or_blocked_uids
    (removing.map(&:uid) & removed.map(&:uid)).uniq
  end

  def blocking_or_blocked
    uids = blocking_or_blocked_uids
    removing.select { |f| uids.include?(f.uid.to_i) }
  end

  def replying_uids(uniq: true)
    uids = statuses.select { |status| !status.text.start_with? 'RT' }.map { |status| status&.entities&.user_mentions&.map { |obj| obj['id'] } }&.flatten.compact
    uniq ? uids.uniq : uids
  end

  def replying(uniq: true)
    return [] if statuses.empty?

    # statuses.map { |status| status&.entities&.user_mentions&.map { |obj| obj['id'] } }&.flatten.compact
    screen_names = statuses.map { |status| $1 if status.text.match /^(?:\.)?@(\w+)( |\W)/ }.compact
    screen_names.uniq! if uniq
    users =
      TwitterDB::User.where(screen_name: screen_names).map do |user|
        Hashie::Mash.new(
          id: user.uid,
          screen_name: user.screen_name,
          statuses_count: user.statuses_count,
          friends_count: user.friends_count,
          followers_count: user.followers_count,
          description: user.description,
          profile_image_url_https: user.profile_image_url_https,
          profile_banner_url: user.profile_banner_url,
          profile_link_color: user.profile_link_color
        )
      end.index_by(&:screen_name)
    users = screen_names.map { |screen_name| users[screen_name] }.compact
    users.each { |user| user.uid = user.id }
  end

  def replied_uids(uniq: true, login_user: nil)
    uids =
      if login_user && login_user.uid.to_i == uid.to_i
        mentions.map { |mention| mention&.user&.id }
      elsif search_results.any?
        search_results.select { |status| !status.text.start_with?('RT') && status.text.include?(mention_name) }.map { |status| status&.user&.id }.compact
      else
        []
      end
    uniq ? uids.uniq : uids
  end

  # TODO do not use login_user
  def replied(uniq: true, login_user: nil)
    users =
      if login_user && login_user.uid.to_i == uid.to_i
        mentions.map(&:user)
      elsif search_results.any?
        search_results.map { |status| status.user if status.text.match /^(?:\.)?@(\w+)( |\W)/ }.compact
      else
        []
      end

    users.uniq!(&:id) if uniq
    users.each { |user| user.uid = user.id }
  end

  def favoriting_uids(uniq: true, min: 0)
    uids = favorites.map { |fav| fav&.user&.id }.each_with_object(Hash.new(0)) { |uid, memo| memo[uid] += 1 }.sort_by { |_, v| -v }.map(&:first)
    uniq ? uids.uniq : uids
  end

  def favoriting(uniq: true, min: 0)
    users = client.favoriting(favorites.to_a, uniq: uniq, min: min)
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
    []
  end

  def inactive_mutual_friends
    []
  end

  def close_friend_uids(uniq: false, min: 1, limit: 50, login_user: nil)
    uids = replying_uids(uniq: uniq) + replied_uids(uniq: uniq, login_user: login_user) + favoriting_uids(uniq: uniq, min: min)
    uids.each_with_object(Hash.new(0)) { |uid, memo| memo[uid] += 1 }.sort_by { |_, v| -v }.take(limit).map(&:first)
  end

  def close_friends(uniq: false, min: 1, limit: 50, login_user: nil)
    material = {
      replying: replying(uniq: uniq),
      replied: replied(uniq: uniq, login_user: login_user),
      favoriting: favoriting(uniq: uniq, min: min)
    }
    users = client.close_friends(Hashie::Mash.new(material), uniq: uniq, min: min, limit: limit)
    users.each { |user| user.uid = user.id }
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
