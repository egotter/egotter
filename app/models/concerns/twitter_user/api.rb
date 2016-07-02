require 'active_support/concern'

module Concerns::TwitterUser::Api
  extend ActiveSupport::Concern

  included do
    def dummy_client
      @dummy_client ||= TwitterWithAutoPagination::Client.new
    end

    def one_sided_friends
      dummy_client.one_sided_friends(self)
    end

    def one_sided_followers
      dummy_client.one_sided_followers(self)
    end

    def mutual_friends
      dummy_client.mutual_friends(self)
    end

    def common_friends(other)
      return [] if other.blank?
      dummy_client.common_friends(self, other)
    end

    def common_followers(other)
      return [] if other.blank?
      dummy_client.common_followers(self, other)
    end

    def removing
      return [] unless TwitterUser.has_more_than_two_records?(uid, user_id)
      TwitterUser.where(uid: uid, user_id: user_id).order(created_at: :asc).each_cons(2).map do |old_one, new_one|
        dummy_client.removing(old_one, new_one)
      end.flatten
    end

    def removed_by
      return [] unless TwitterUser.has_more_than_two_records?(uid, user_id)
      TwitterUser.where(uid: uid, user_id: user_id).order(created_at: :asc).each_cons(2).map do |old_one, new_one|
        dummy_client.removed_by(old_one, new_one)
      end.flatten
    end

    def replying(options = {})
      if statuses.any?
        client.replying(statuses.to_a, options)
      else
        client.replying(uid.to_i, options)
      end.map { |u| u.uid = u.id; u }
    end

    def replied(options = {})
      result =
        if ego_surfing?
          if mentions.any?
            mentions.map { |m| m.user }.map { |u| u.uid = u.id; u }
          else
            client.replied(uid.to_i, options)
          end
        elsif search_results.any?
          uids = dummy_client._extract_uids(search_results.to_a)
          dummy_client._extract_users(search_results.to_a, uids)
        else
          client.replied(uid.to_i, options)
        end.map { |u| u.uid = u.id; u }

      (options.has_key?(:uniq) && !options[:uniq]) ? result : result.uniq { |u| u.uid.to_i }
    end

    def favoriting(options = {})
      if favorites.any?
        client.favoriting(favorites.to_a, options)
      else
        client.favoriting(uid.to_i, options)
      end.map { |u| u.uid = u.id; u }
    end

    def inactive_friends
      dummy_client._extract_inactive_users(friends, authorized: ego_surfing?)
    end

    def inactive_followers
      dummy_client._extract_inactive_users(followers, authorized: ego_surfing?)
    end

    def clusters_belong_to
      text = statuses.map{|s| s.text }.join(' ')
      dummy_client.clusters_belong_to(text)
    end

    def close_friends(options = {})
      min = options.has_key?(:min) ? options.delete(:min) : 1
      options.merge!(uniq: false, min: min)
      user = Hashie::Mash.new({
                                replying: replying(options),
                                replied: replied(options),
                                favoriting: favoriting(options)

                              })

      client.close_friends(user, options).map { |u| u.uid = u.id; u }
    end

    def inactive_friends_graph
      inactive_friends_size = inactive_friends.size
      friends_size = friends_count
      [
        {name: I18n.t('legend.inactive_friends'), y: (inactive_friends_size.to_f / friends_size * 100)},
        {name: I18n.t('legend.not_inactive_friends'), y: ((friends_size - inactive_friends_size).to_f / friends_size * 100)}
      ]
    end

    def inactive_followers_graph
      inactive_followers_size = inactive_followers.size
      followers_size = followers_count
      [
        {name: I18n.t('legend.inactive_followers'), y: (inactive_followers_size.to_f / followers_size * 100)},
        {name: I18n.t('legend.not_inactive_followers'), y: ((followers_size - inactive_followers_size).to_f / followers_size * 100)}
      ]
    end

    def removing_graph
      large_rate = [removing.size * 10, 100].min
      [
        {name: I18n.t('legend.large'), y: large_rate},
        {name: I18n.t('legend.small'), y: 100 - large_rate}
      ]
    end

    def removed_by_graph
      large_rate = [removed_by.size * 10, 100].min
      [
        {name: I18n.t('legend.large'), y: large_rate},
        {name: I18n.t('legend.small'), y: 100 - large_rate}
      ]
    end

    def replying_graph
      friends_size = friends_count
      replying_size = replying.size
      [
        {name: I18n.t('legend.replying'), y: (replying_size.to_f / friends_size * 100)},
        {name: I18n.t('legend.others'), y: ((friends_size - replying_size).to_f / friends_size * 100)}
      ]
    end

    def replied_graph
      followers_size = followers_count
      replied_size = replied.size
      [
        {name: I18n.t('legend.replying'), y: (replied_size.to_f / followers_size * 100)},
        {name: I18n.t('legend.others'), y: ((followers_size - replied_size).to_f / followers_size * 100)}
      ]
    end

    def favoriting_graph
      friends_size = friends_count
      favoriting_size = favoriting.size
      [
        {name: I18n.t('legend.favoriting'), y: (favoriting_size.to_f / friends_size * 100)},
        {name: I18n.t('legend.others'), y: ((friends_size - favoriting_size).to_f / friends_size * 100)}
      ]
    end

    def close_friends_graph(options = {})
      items = close_friends(options.merge(min: 0))
      items_size = items.size
      good = percentile_index(items, 0.10) + 1
      not_so_bad = percentile_index(items, 0.50) + 1
      so_so = percentile_index(items, 1.0) + 1
      [
        {name: I18n.t('legend.close_friends'), y: (good.to_f / items_size * 100), drilldown: 'good', sliced: true, selected: true},
        {name: I18n.t('legend.friends'), y: ((not_so_bad - good).to_f / items_size * 100), drilldown: 'not_so_bad'},
        {name: I18n.t('legend.acquaintance'), y: ((so_so - (good + not_so_bad)).to_f / items_size * 100), drilldown: 'so_so'}
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
        {name: I18n.t('legend.one_sided_friends'), y: (one_sided_size.to_f / friends_size * 100)},
        {name: I18n.t('legend.others'), y: ((friends_size - one_sided_size).to_f / friends_size * 100)}
      ]
    end

    def one_sided_followers_graph
      followers_size = followers.size
      one_sided_size = one_sided_followers.size
      [
        {name: I18n.t('legend.one_sided_followers'), y: (one_sided_size.to_f / followers_size * 100)},
        {name: I18n.t('legend.others'), y: ((followers_size - one_sided_size).to_f / followers_size * 100)}
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
        {name: I18n.t('legend.mutual_friends'), y: rates[0], sliced: sliced, selected: sliced},
        {name: I18n.t('legend.one_sided_friends'), y: rates[1]},
        {name: I18n.t('legend.one_sided_followers'), y: rates[2]}
      ]
    end

    def common_friends_graph(other)
      friends_size = friends.size
      common_friends_size = common_friends(other).size
      [
        {name: I18n.t('legend.common_friends'), y: (common_friends_size.to_f / friends_size * 100)},
        {name: I18n.t('legend.others'), y: ((friends_size - common_friends_size).to_f / friends_size * 100)}
      ]
    end

    def common_followers_graph(other)
      followers_size = followers.size
      common_followers_size = common_followers(other).size
      [
        {name: I18n.t('legend.common_followers'), y: (common_followers_size.to_f / followers_size * 100)},
        {name: I18n.t('legend.others'), y: ((followers_size - common_followers_size).to_f / followers_size * 100)}
      ]
    end

    def usage_stats_graph
      client.usage_stats(__uid_i, tweets: statuses)
    end

    def frequency_distribution(words)
      words.map { |word, count| {name: word, y: count} }
    end

    def clusters_belong_to_cloud
      clusters_belong_to.map.with_index { |(h, c), i| {text: h, size: c, group: i % 20} }
    end

    def clusters_belong_to_frequency_distribution
      frequency_distribution(clusters_belong_to.to_a.slice(0, 10))
    end

    def percentile_index(ary, percentile = 0.0)
      ((ary.length * percentile).ceil) - 1
    end

    def hashtags
      statuses.select { |s| s.hashtags? }.map { |s| s.hashtags }.flatten.
        each_with_object(Hash.new(0)) { |h, memo| memo[h] += 1 }.sort_by { |_, v| -v }.to_h
    end

    def hashtags_cloud
      hashtags.map.with_index { |(h, c), i| {text: h, size: c, group: i % 20} }
    end

    def hashtags_frequency_distribution
      frequency_distribution(hashtags.to_a.slice(0, 10))
    end

    def usage_stats(options = {})
      client.usage_stats(__uid_i, options)
    end
  end
end