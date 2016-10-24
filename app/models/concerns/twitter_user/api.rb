require 'active_support/concern'

module Concerns::TwitterUser::Api
  extend ActiveSupport::Concern

  included do
  end

  def dummy_client
    @dummy_client ||= ApiClient.dummy_instance
  end

  def one_sided_friends
    @_one_sided_friends ||= cached_friends - cached_followers
  end

  def one_sided_followers
    @_one_sided_followers ||= cached_followers - cached_friends
  end

  def mutual_friends
    @_mutual_friends ||= cached_friends & cached_followers
  end

  def common_friends(other)
    return [] if other.blank?
    @_common_friends ||= cached_friends & other.cached_friends
  end

  def common_followers(other)
    return [] if other.blank?
    @_common_followers ||= cached_followers & other.cached_followers
  end

  def latest_removing
    return [] unless cached_many?
    newer, older = TwitterUser.where(uid: uid).order(created_at: :desc).reject{|tu| tu.friendless? }.take(2)
    return [] if newer.cached_friends.empty?
    (older.cached_friends - newer.cached_friends)
  end

  # `includes` is not used because friends have hundreds of records.
  def removing
    return [] unless cached_many?
    @_removing ||= TwitterUser.where(uid: uid).order(created_at: :asc).reject{|tu| tu.friendless? }.each_cons(2).map do |older, newer|
      next if newer.cached_friends.empty?
      older.cached_friends - newer.cached_friends
    end.compact.flatten.reverse
  end

  def latest_removed
    return [] unless cached_many?
    newer, older = TwitterUser.where(uid: uid).order(created_at: :desc).reject { |tu| tu.friendless? }.take(2)
    return [] if newer.cached_followers.empty?
    (older.cached_followers - newer.cached_followers)
  end

  # `includes` is not used because followers have hundreds of records.
  def removed
    return [] unless cached_many?
    @_removed ||= TwitterUser.where(uid: uid).order(created_at: :asc).reject { |tu| tu.friendless? }.each_cons(2).map do |older, newer|
      next if newer.cached_followers.empty?
      older.cached_followers - newer.cached_followers
    end.compact.flatten.reverse
  end

  def new_friends
    return [] unless cached_many?
    newer, older = TwitterUser.where(uid: uid).order(created_at: :desc).reject { |tu| tu.friendless? }.take(2)
    return [] if older.cached_friends.empty?
    (newer.cached_friends - older.cached_friends)
  end

  def new_followers
    return [] unless cached_many?
    newer, older = TwitterUser.where(uid: uid).order(created_at: :desc).reject { |tu| tu.friendless? }.take(2)
    return [] if older.cached_followers.empty?
    (newer.cached_followers - older.cached_followers)
  end

  def blocking_or_blocked
    @_blocking_or_blocked ||= (removing & removed).uniq
  end

  def replying(uniq: true)
    if statuses.any?
      client.replying(statuses.to_a, uniq: uniq)
    else
      client.replying(uid.to_i, uniq: uniq)
    end.map { |u| u.uid = u.id; u }
  end

  def replied(uniq: true, login_user: nil)
    result =
      if login_user && login_user.uid.to_i == uid.to_i
        if mentions.any?
          mentions.map { |m| m.user }
        else
          client.replied(uid.to_i, uniq: uniq)
        end
      elsif search_results.any?
        uids = dummy_client._extract_uids(search_results.to_a)
        dummy_client._extract_users(search_results.to_a, uids)
      else
        client.replied(uid.to_i, uniq: uniq)
      end.map { |u| u.uid = u.id; u }

    uniq ? result.uniq { |u| u.uid.to_i } : result
  end

  def favoriting(uniq: true, min: 0)
    if favorites.any?
      client.favoriting(favorites.to_a, uniq: uniq, min: min)
    else
      client.favoriting(uid.to_i, uniq: uniq, min: min)
    end.map { |u| u.uid = u.id; u }
  end

  def inactive_friends
    @_inactive_friends ||= dummy_client._extract_inactive_users(cached_friends)
  end

  def inactive_followers
    @_inactive_followers ||= dummy_client._extract_inactive_users(cached_followers)
  end

  def clusters_belong_to
    dummy_client.tweet_clusters(statuses, limit: 100)
  end

  def close_friends(uniq: false, min: 1, limit: 50, login_user: nil)
    user = {
      replying: replying(uniq: uniq),
      replied: replied(uniq: uniq, login_user: login_user),
      favoriting: favoriting(uniq: uniq, min: min)
    }
    client.close_friends(Hashie::Mash.new(user), uniq: uniq, min: min, limit: limit).map { |u| u.uid = u.id; u }
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

  def replying_graph
    friends_size = friends_count
    replying_size = [replying.size, friends_size].min
    [
      {name: I18n.t('searches.replying.targets'), y: (replying_size.to_f / friends_size * 100)},
      {name: I18n.t('searches.common.others'), y: ((friends_size - replying_size).to_f / friends_size * 100)}
    ]
  end

  def replied_graph(login_user: nil)
    followers_size = followers_count
    replied_size = [replied(login_user: login_user).size, followers_size].min
    [
      {name: I18n.t('searches.replied.targets'), y: (replied_size.to_f / followers_size * 100)},
      {name: I18n.t('searches.common.others'), y: ((followers_size - replied_size).to_f / followers_size * 100)}
    ]
  end

  def favoriting_graph
    friends_size = friends_count
    favoriting_size = [favoriting.size, friends_size].min
    [
      {name: I18n.t('searches.favoriting.targets'), y: (favoriting_size.to_f / friends_size * 100)},
      {name: I18n.t('searches.common.others'), y: ((friends_size - favoriting_size).to_f / friends_size * 100)}
    ]
  end

  def close_friends_graph(login_user: nil)
    items = close_friends(min: 0, login_user: login_user)
    items_size = items.size
    good = percentile_index(items, 0.10) + 1
    not_so_bad = percentile_index(items, 0.50) + 1
    so_so = percentile_index(items, 1.0) + 1
    [
      {name: I18n.t('searches.close_friends.targets'), y: (good.to_f / items_size * 100), drilldown: 'good', sliced: true, selected: true},
      {name: I18n.t('searches.close_friends.friends'), y: ((not_so_bad - good).to_f / items_size * 100), drilldown: 'not_so_bad'},
      {name: I18n.t('searches.close_friends.acquaintance'), y: ((so_so - (good + not_so_bad)).to_f / items_size * 100), drilldown: 'so_so'}
    ]
    # drilldown_series = [
    #   {name: 'good', id: 'good', data: items.slice(0, good - 1).map { |i| [i.screen_name, i.score] }},
    #   {name: 'not_so_bad', id: 'not_so_bad', data: items.slice(good, not_so_bad - 1).map { |i| [i.screen_name, i.score] }},
    #   {name: 'so_so', id: 'so_so', data: items.slice(not_so_bad, so_so - 1).map { |i| [i.screen_name, i.score] }},
    # ]
  end

  def one_sided_friends_graph
    friends_size = cached_friends.size
    one_sided_size = one_sided_friends.size
    [
      {name: I18n.t('searches.one_sided_friends.targets'), y: (one_sided_size.to_f / friends_size * 100)},
      {name: I18n.t('searches.common.others'), y: ((friends_size - one_sided_size).to_f / friends_size * 100)}
    ]
  end

  def one_sided_followers_graph
    followers_size = cached_followers.size
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
    friends_size = cached_friends.size
    common_friends_size = common_friends(other).size
    [
      {name: I18n.t('searches.common_friends.targets'), y: (common_friends_size.to_f / friends_size * 100)},
      {name: I18n.t('searches.common.others'), y: ((friends_size - common_friends_size).to_f / friends_size * 100)}
    ]
  end

  def common_followers_graph(other)
    followers_size = cached_followers.size
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
