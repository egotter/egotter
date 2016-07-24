module MenuItemBuilder
  extend ActiveSupport::Concern

  included do

  end

  def removing_menu(tu)
    {
      name: t('search_menu.removing', user: tu.mention_name),
      target: tu.removing,
      graph: tu.removing_graph,
      path_method: method(:removing_path).to_proc
    }
  end

  def removed_menu(tu)
    {
      name: t('search_menu.removed', user: tu.mention_name),
      target: tu.removed,
      graph: tu.removed_graph,
      path_method: method(:removed_path).to_proc
    }
  end

  def blocking_or_blocked_menu(tu)
    {
      name: t('search_menu.blocking_or_blocked', user: tu.mention_name),
      target: tu.blocking_or_blocked,
      graph: tu.blocking_or_blocked_graph,
      path_method: method(:blocking_or_blocked_path).to_proc
    }
  end

  def mutual_friends_menu(tu)
    {
      name: t('search_menu.mutual_friends', user: tu.mention_name),
      target: tu.mutual_friends,
      graph: tu.mutual_friends_graph,
      path_method: method(:mutual_friends_path).to_proc
    }
  end

  def one_sided_friends_menu(tu)
    {
      name: t('search_menu.one_sided_friends', user: tu.mention_name),
      target: tu.one_sided_friends,
      graph: tu.one_sided_friends_graph,
      path_method: method(:one_sided_friends_path).to_proc
    }
  end

  def one_sided_followers_menu(tu)
    {
      name: t('search_menu.one_sided_followers', user: tu.mention_name),
      target: tu.one_sided_followers,
      graph: tu.one_sided_followers_graph,
      path_method: method(:one_sided_followers_path).to_proc
    }
  end

  def replying_menu(tu)
    {
      name: t('search_menu.replying', user: tu.mention_name),
      target: tu.replying,
      graph: tu.replying_graph,
      path_method: method(:replying_path).to_proc
    }
  end

  def replied_menu(tu)
    {
      name: t('search_menu.replied', user: tu.mention_name),
      target: tu.replied,
      graph: tu.replied_graph,
      path_method: method(:replied_path).to_proc
    }
  end

  def favoriting_menu(tu)
    {
      name: t('search_menu.favoriting', user: tu.mention_name),
      target: tu.favoriting,
      graph: tu.favoriting_graph,
      path_method: method(:favoriting_path).to_proc
    }
  end

  def inactive_friends_menu(tu)
    {
      name: t('search_menu.inactive_friends', user: tu.mention_name),
      target: tu.inactive_friends,
      graph: tu.inactive_friends_graph,
      path_method: method(:inactive_friends_path).to_proc
    }
  end

  def inactive_followers_menu(tu)
    {
      name: t('search_menu.inactive_followers', user: tu.mention_name),
      target: tu.inactive_followers,
      graph: tu.inactive_followers_graph,
      path_method: method(:inactive_followers_path).to_proc
    }
  end

  def common_friend_and_followers_menu(tu)
    sn = tu.mention_name
    friends_name = t('search_menu.common_friends', user: sn, login: t('dictionary.you'))
    followers_name = t('search_menu.common_followers', user: sn, login: t('dictionary.you'))

    if search_oneself?(tu.uid)
      [
        {
          name: friends_name,
          target: [],
          path_method: method(:common_friends_path).to_proc
        }, {
          name: followers_name,
          target: [],
          path_method: method(:common_followers_path).to_proc
        },
      ]
    elsif search_others?(tu.uid)
      current_user_tu = current_user.twitter_user
      [
        {
          name: friends_name,
          target: tu.common_friends(current_user_tu),
          graph: tu.common_friends_graph(current_user_tu),
          path_method: method(:common_friends_path).to_proc
        }, {
          name: followers_name,
          target: tu.common_followers(current_user_tu),
          graph: tu.common_followers_graph(current_user_tu),
          path_method: method(:common_followers_path).to_proc
        },
      ]
    elsif !user_signed_in?
      [
        {
          name: friends_name,
          target: [],
          path_method: method(:common_friends_path).to_proc
        }, {
          name: followers_name,
          target: [],
          path_method: method(:common_followers_path).to_proc
        },
      ]
    end
  end

  def close_friends_menu(tu)
    {
      name: t('search_menu.close_friends', user: tu.mention_name),
      target: tu.close_friends(cache: :read),
      graph: tu.close_friends_graph(cache: :read),
      path_method: method(:close_friends_path).to_proc
    }
  end

  def usage_stats_menu(tu)
    {
      name: t('search_menu.usage_stats', user: tu.mention_name),
      graph: tu.usage_stats_graph,
      path_method: method(:usage_stats_path).to_proc
    }
  end

  def clusters_belong_to_menu(tu)
    sn = tu.mention_name
    clusters_belong_to = tu.clusters_belong_to
    {
      name: t('search_menu.clusters_belong_to', user: sn),
      target: clusters_belong_to,
      graph: tu.clusters_belong_to_frequency_distribution,
      screen_name: tu.screen_name,
      text: "#{clusters_belong_to.map{|c| "#{c}#{t('dictionary.cluster')}" }.join(t('dictionary.delim'))}",
      tweet_text: "#{t('search_menu.clusters_belong_to', user: sn)}\n#{clusters_belong_to.map{|c| "##{c}#{t('dictionary.cluster')}" }.join(' ')}\n#{t('dictionary.continue_reading')}http://example.com",
      path_method: method(:clusters_belong_to_path).to_proc
    }
  end

  def update_histories_menu(tu)
    {
      name: t('search_menu.update_histories', user: tu.mention_name),
      target: UpdateHistories.new(tu.uid, current_user_id),
      path_method: method(:update_history_path).to_proc
    }
  end
end