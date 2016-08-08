class TwitterUserDecorator < Draper::Decorator
  def removing_menu
    {
      name: t('searches.removing.title', user: object.mention_name),
      target: object.removing,
      graph: object.removing_graph,
      path: h.removing_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def removed_menu
    {
      name: t('searches.removed.title', user: object.mention_name),
      target: object.removed,
      graph: object.removed_graph,
      path: h.removed_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def blocking_or_blocked_menu
    {
      name: t('searches.blocking_or_blocked.title', user: object.mention_name),
      target: object.blocking_or_blocked,
      graph: object.blocking_or_blocked_graph,
      path: h.blocking_or_blocked_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def mutual_friends_menu
    {
      name: t('searches.mutual_friends.title', user: object.mention_name),
      target: object.mutual_friends,
      graph: object.mutual_friends_graph,
      path: h.mutual_friends_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def one_sided_friends_menu
    {
      name: t('searches.one_sided_friends.title', user: object.mention_name),
      target: object.one_sided_friends,
      graph: object.one_sided_friends_graph,
      path: h.one_sided_friends_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def one_sided_followers_menu
    {
      name: t('searches.one_sided_followers.title', user: object.mention_name),
      target: object.one_sided_followers,
      graph: object.one_sided_followers_graph,
      path: h.one_sided_followers_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def replying_menu
    {
      name: t('searches.replying.title', user: object.mention_name),
      target: object.replying,
      graph: object.replying_graph,
      path: h.replying_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def replied_menu
    {
      name: t('searches.replied.title', user: object.mention_name),
      target: object.replied,
      graph: object.replied_graph,
      path: h.replied_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def favoriting_menu
    {
      name: t('searches.favoriting.title', user: object.mention_name),
      target: object.favoriting,
      graph: object.favoriting_graph,
      path: h.favoriting_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def inactive_friends_menu
    {
      name: t('searches.inactive_friends.title', user: object.mention_name),
      target: object.inactive_friends,
      graph: object.inactive_friends_graph,
      path: h.inactive_friends_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def inactive_followers_menu
    {
      name: t('searches.inactive_followers.title', user: object.mention_name),
      target: object.inactive_followers,
      graph: object.inactive_followers_graph,
      path: h.inactive_followers_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def common_friend_and_followers_menu
    sn = object.mention_name
    friends_name = t('searches.common_friends.title', user: sn, login: t('dictionary.you'))
    followers_name = t('searches.common_followers.title', user: sn, login: t('dictionary.you'))

    if h.search_oneself?(object.uid)
      [
        {
          name: friends_name,
          target: [],
          path: h.common_friends_path(screen_name: object.screen_name, id: object.uid)
        }, {
          name: followers_name,
          target: [],
          path: h.common_followers_path(screen_name: object.screen_name, id: object.uid)
        },
      ]
    elsif h.search_others?(object.uid)
      current_user_tu = h.current_user.twitter_user
      [
        {
          name: friends_name,
          target: object.common_friends(current_user_tu),
          graph: object.common_friends_graph(current_user_tu),
          path: h.common_friends_path(screen_name: object.screen_name, id: object.uid)
        }, {
          name: followers_name,
          target: object.common_followers(current_user_tu),
          graph: object.common_followers_graph(current_user_tu),
          path: h.common_followers_path(screen_name: object.screen_name, id: object.uid)
        },
      ]
    elsif !h.user_signed_in?
      [
        {
          name: friends_name,
          target: [],
          path: h.common_friends_path(screen_name: object.screen_name, id: object.uid)
        }, {
          name: followers_name,
          target: [],
          path: h.common_followers_path(screen_name: object.screen_name, id: object.uid)
        },
      ]
    end
  end

  def close_friends_menu
    {
      name: t('searches.close_friends.title', user: object.mention_name),
      target: object.close_friends(cache: :read),
      graph: object.close_friends_graph(cache: :read),
      path: h.close_friends_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def usage_stats_menu
    {
      name: t('searches.usage_stats.title', user: object.mention_name),
      graph: object.usage_stats_graph,
      path: h.usage_stats_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def clusters_belong_to_menu
    sn = object.mention_name
    title = t('searches.clusters_belong_to.title', user: sn)
    clusters_belong_to = object.clusters_belong_to
    {
      name: title,
      target: clusters_belong_to,
      graph: object.clusters_belong_to_frequency_distribution,
      screen_name: object.screen_name,
      text: "#{clusters_belong_to.map{|c| "#{c}#{t('searches.clusters_belong_to.cluster')}" }.join(t('dictionary.delim'))}",
      tweet_text: "#{title}\n#{clusters_belong_to.map{|c| "##{c}#{t('searches.clusters_belong_to.cluster')}" }.join(' ')}\n#{t('dictionary.continue_reading')}http://example.com",
      path: h.clusters_belong_to_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def update_histories_menu
    {
      name: t('update_histories.show.title', user: object.mention_name),
      target: UpdateHistories.new(object.uid, current_user_id),
      path: h.update_history_path(screen_name: object.screen_name, id: object.uid)
    }
  end
end
