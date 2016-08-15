class TwitterUserDecorator < Draper::Decorator
  %i(removing removed new_friends new_followers blocking_or_blocked mutual_friends
     one_sided_friends one_sided_followers replying replied favoriting inactive_friends inactive_followers).each do |menu|
    define_method("#{menu}_menu") do
      {
        name: I18n.t("searches.#{menu}.title", user: object.mention_name),
        target: object.send(menu),
        graph: object.send("#{menu}_graph"),
        path: h.send("#{menu}_path", screen_name: object.screen_name, id: object.uid)
      }
    end
  end

  def common_friend_and_followers_menu
    sn = object.mention_name
    friends_name = I18n.t('searches.common_friends.title', user: sn, login: I18n.t('dictionary.you'))
    followers_name = I18n.t('searches.common_followers.title', user: sn, login: I18n.t('dictionary.you'))

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
      name: I18n.t('searches.close_friends.title', user: object.mention_name),
      target: object.close_friends(cache: :read),
      graph: object.close_friends_graph(cache: :read),
      path: h.close_friends_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def usage_stats_menu
    {
      name: I18n.t('searches.usage_stats.title', user: object.mention_name),
      graph: object.usage_stats_graph,
      path: h.usage_stats_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def clusters_belong_to_menu
    sn = object.mention_name
    title = I18n.t('searches.clusters_belong_to.title', user: sn)
    clusters_belong_to = object.clusters_belong_to
    {
      name: title,
      target: clusters_belong_to,
      graph: object.clusters_belong_to_frequency_distribution,
      screen_name: object.screen_name,
      text: "#{clusters_belong_to.map{|c| "#{c}#{I18n.t('searches.common.cluster')}" }.join(I18n.t('dictionary.delim'))}",
      tweet_text: "#{title}\n#{clusters_belong_to.map{|c| "##{c}#{I18n.t('searches.common.cluster')}" }.join(' ')}\n#{I18n.t('dictionary.continue_reading')}http://example.com",
      path: h.clusters_belong_to_path(screen_name: object.screen_name, id: object.uid)
    }
  end

  def update_histories_menu
    {
      name: I18n.t('update_histories.show.title', user: object.mention_name),
      target: UpdateHistories.new(object.uid, h.current_user_id),
      path: h.update_history_path(screen_name: object.screen_name, id: object.uid)
    }
  end
end
