require 'active_support/concern'

module Concerns::TwitterUser::Api
  extend ActiveSupport::Concern

  included do
  end

  def dummy_client
    ApiClient.dummy_instance
  end

  def one_sided_friends
    uids = friend_uids - follower_uids
    uids.empty? ? [] : friends.where(uid: uids)
  end

  def one_sided_followers
    uids = follower_uids - friend_uids
    uids.empty? ? [] : followers.where(uid: uids)
  end

  def mutual_friends
    uids = friend_uids & follower_uids
    uids.empty? ? [] : friends.where(uid: uids)
  end

  def common_friends(other)
    uids = friend_uids & other.friend_uids
    uids.empty? ? [] : friends.where(uid: uids)
  end

  def common_followers(other)
    uids = follower_uids & other.follower_uids
    uids.empty? ? [] : followers.where(uid: uids)
  end

  def new_removing
    return [] unless self.class.many?(uid)
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return [] if newer.nil? || older.nil? || newer.friends_size == 0
    uids = older.friend_uids - newer.friend_uids
    uids.empty? ? [] : older.friends.where(uid: uids)
  end

  def calc_removing
    return [] unless self.class.many?(uid)
    TwitterUser.with_friends.where(uid: uid).order(created_at: :asc).each_cons(2).map do |older, newer|
      next if newer.nil? || older.nil? || newer.friends_size == 0
      uids = older.friend_uids - newer.friend_uids
      uids.empty? ? [] : older.friends.where(uid: uids)
    end.compact.flatten.reverse
  end

  def removing
    unfriends.any? ? unfriends : calc_removing
  end

  def new_removed
    return [] unless self.class.many?(uid)
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return [] if newer.nil? || older.nil? || newer.followers_size == 0
    uids = older.follower_uids - newer.follower_uids
    uids.empty? ? [] : older.followers.where(uid: uids)
  end

  def calc_removed
    return [] unless self.class.many?(uid)
    TwitterUser.with_friends.where(uid: uid).order(created_at: :asc).each_cons(2).map do |older, newer|
      next if newer.nil? || older.nil? || newer.followers_size == 0
      uids = older.follower_uids - newer.follower_uids
      uids.empty? ? [] : older.followers.where(uid: uids)
    end.compact.flatten.reverse
  end

  def removed
    unfollowers.any? ? unfollowers : calc_removed
  end

  def new_friends
    return [] unless self.class.many?(uid)
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return [] if newer.nil? || older.nil? || older.friends_size == 0
    uids = newer.friend_uids - older.friend_uids
    uids.empty? ? [] : newer.friends.where(uid: uids)
  end

  def new_followers
    return [] unless self.class.many?(uid)
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return [] if newer.nil? || older.nil? || older.followers_size == 0
    uids = newer.follower_uids - older.follower_uids
    uids.empty? ? [] : newer.followers.where(uid: uids)
  end

  def blocking_or_blocked
    uids = (removing.map { |f| f.uid.to_i } & removed.map { |f| f.uid.to_i }).uniq
    removing.select { |f| uids.include?(f.uid.to_i) }
  end

  def replying(uniq: true)
    return [] if statuses.empty?

    # statuses.map { |status| status&.entities&.user_mentions&.map { |obj| obj['id'] } }&.flatten.compact
    screen_names = statuses.map { |status| $1 if status.text.match /^(?:\.)?@(\w+)( |\W)/ }.compact
    screen_names.uniq! if uniq
    client.users(screen_names).each do |user|
      user.uid = user.id
      user.mention_name = "@#{user.screen_name}"
    end
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

    users.each do |user|
      user.uid = user.id
      user.mention_name = "@#{user.screen_name}"
    end
  end

  def favoriting(uniq: true, min: 0)
    users = client.favoriting(favorites.to_a, uniq: uniq, min: min)

    users.each do |user|
      user.uid = user.id
      user.mention_name = "@#{user.screen_name}"
    end
  end

  def inactive_friends
    dummy_client._extract_inactive_users(friends)
  end

  def inactive_followers
    dummy_client._extract_inactive_users(followers)
  end

  def clusters_belong_to
    dummy_client.tweet_clusters(statuses, limit: 100)
  end

  def close_friends(uniq: false, min: 1, limit: 50, login_user: nil)
    material = {
      replying: replying(uniq: uniq),
      replied: replied(uniq: uniq, login_user: login_user),
      favoriting: favoriting(uniq: uniq, min: min)
    }
    users = client.close_friends(Hashie::Mash.new(material), uniq: uniq, min: min, limit: limit)
    users.each do |user|
      user.uid = user.id
      user.mention_name = "@#{user.screen_name}"
    end
  end

  def inactive_friends_graph
    inactive_friends_size = inactive_friends.size
    friends_size = friends_count
    [
      {name: I18n.t('searches.inactive_friends.targets'), y: (inactive_friends_size.to_f / friends_size * 100)},
      {name: I18n.t('searches.common.others'), y: ((friends_size - inactive_friends_size).to_f / friends_size * 100)}
    ]
  end

  def inactive_followers_graph
    inactive_followers_size = inactive_followers.size
    followers_size = followers_count
    [
      {name: I18n.t('searches.inactive_followers.targets'), y: (inactive_followers_size.to_f / followers_size * 100)},
      {name: I18n.t('searches.common.others'), y: ((followers_size - inactive_followers_size).to_f / followers_size * 100)}
    ]
  end

  def removing_graph
    large_rate = [removing.size * 10, 100].min
    [
      {name: I18n.t('searches.common.large'), y: large_rate},
      {name: I18n.t('searches.common.small'), y: 100 - large_rate}
    ]
  end

  def removed_graph
    large_rate = [removed.size * 10, 100].min
    [
      {name: I18n.t('searches.common.large'), y: large_rate},
      {name: I18n.t('searches.common.small'), y: 100 - large_rate}
    ]
  end

  def new_friends_graph
    large_rate = [new_friends.size * 10, 100].min
    [
      {name: I18n.t('searches.common.large'), y: large_rate},
      {name: I18n.t('searches.common.small'), y: 100 - large_rate}
    ]
  end

  def new_followers_graph
    large_rate = [new_followers.size * 10, 100].min
    [
      {name: I18n.t('searches.common.large'), y: large_rate},
      {name: I18n.t('searches.common.small'), y: 100 - large_rate}
    ]
  end

  def blocking_or_blocked_graph
    large_rate = [blocking_or_blocked.size * 10, 100].min
    [
      {name: I18n.t('searches.common.large'), y: large_rate},
      {name: I18n.t('searches.common.small'), y: 100 - large_rate}
    ]
  end

  def replying_graph(users)
    friends_size = friends_count
    replying_size = [users.size, friends_size].min
    [
      {name: I18n.t('searches.replying.targets'), y: (replying_size.to_f / friends_size * 100)},
      {name: I18n.t('searches.common.others'), y: ((friends_size - replying_size).to_f / friends_size * 100)}
    ]
  end

  def replied_graph(users)
    followers_size = followers_count
    replied_size = [users.size, followers_size].min
    [
      {name: I18n.t('searches.replied.targets'), y: (replied_size.to_f / followers_size * 100)},
      {name: I18n.t('searches.common.others'), y: ((followers_size - replied_size).to_f / followers_size * 100)}
    ]
  end

  def favoriting_graph(users)
    friends_size = friends_count
    favoriting_size = [users.size, friends_size].min
    [
      {name: I18n.t('searches.favoriting.targets'), y: (favoriting_size.to_f / friends_size * 100)},
      {name: I18n.t('searches.common.others'), y: ((friends_size - favoriting_size).to_f / friends_size * 100)}
    ]
  end

  def close_friends_graph(users)
    users_size = users.size
    good = percentile_index(users, 0.10) + 1
    not_so_bad = percentile_index(users, 0.50) + 1
    so_so = percentile_index(users, 1.0) + 1
    [
      {name: I18n.t('searches.close_friends.targets'), y: (good.to_f / users_size * 100), drilldown: 'good', sliced: true, selected: true},
      {name: I18n.t('searches.close_friends.friends'), y: ((not_so_bad - good).to_f / users_size * 100), drilldown: 'not_so_bad'},
      {name: I18n.t('searches.close_friends.acquaintance'), y: ((so_so - (good + not_so_bad)).to_f / users_size * 100), drilldown: 'so_so'}
    ]
    # drilldown_series = [
    #   {name: 'good', id: 'good', data: items.slice(0, good - 1).map { |i| [i.screen_name, i.score] }},
    #   {name: 'not_so_bad', id: 'not_so_bad', data: items.slice(good, not_so_bad - 1).map { |i| [i.screen_name, i.score] }},
    #   {name: 'so_so', id: 'so_so', data: items.slice(not_so_bad, so_so - 1).map { |i| [i.screen_name, i.score] }},
    # ]
  end

  def one_sided_friends_graph
    friends_size = friends.size
    one_sided_size = one_sided_friends.size
    [
      {name: I18n.t('searches.one_sided_friends.targets'), y: (one_sided_size.to_f / friends_size * 100)},
      {name: I18n.t('searches.common.others'), y: ((friends_size - one_sided_size).to_f / friends_size * 100)}
    ]
  end

  def one_sided_followers_graph
    followers_size = followers.size
    one_sided_size = one_sided_followers.size
    [
      {name: I18n.t('searches.one_sided_followers.targets'), y: (one_sided_size.to_f / followers_size * 100)},
      {name: I18n.t('searches.common.others'), y: ((followers_size - one_sided_size).to_f / followers_size * 100)}
    ]
  end

  def mutual_friends_rate
    friendship_size = friends_count + followers_count
    return [0.0, 0.0, 0.0] if friendship_size == 0
    [
      mutual_friends.size.to_f / friendship_size * 100,
      one_sided_friends.size.to_f / friendship_size * 100,
      one_sided_followers.size.to_f / friendship_size * 100
    ]
  end

  def mutual_friends_graph
    rates = mutual_friends_rate
    sliced = rates[0] < 25
    [
      {name: I18n.t('searches.mutual_friends.targets'), y: rates[0], sliced: sliced, selected: sliced},
      {name: I18n.t('searches.one_sided_friends.targets'), y: rates[1]},
      {name: I18n.t('searches.one_sided_followers.targets'), y: rates[2]}
    ]
  end

  def common_friends_graph(other)
    friends_size = friends.size
    common_friends_size = common_friends(other).size
    [
      {name: I18n.t('searches.common_friends.targets'), y: (common_friends_size.to_f / friends_size * 100)},
      {name: I18n.t('searches.common.others'), y: ((friends_size - common_friends_size).to_f / friends_size * 100)}
    ]
  end

  def common_followers_graph(other)
    followers_size = followers.size
    common_followers_size = common_followers(other).size
    [
      {name: I18n.t('searches.common_followers.targets'), y: (common_followers_size.to_f / followers_size * 100)},
      {name: I18n.t('searches.common.others'), y: ((followers_size - common_followers_size).to_f / followers_size * 100)}
    ]
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
