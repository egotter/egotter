class TwitterUserDecorator < Draper::Decorator
  def common_friend_and_followers_menu
    sn = object.mention_name
    friends_name = I18n.t('searches.common_friends.title', user: sn, login: I18n.t('dictionary.you'))
    followers_name = I18n.t('searches.common_followers.title', user: sn, login: I18n.t('dictionary.you'))
    friends_description = I18n.t('searches.common_friends.description', user: sn, login: I18n.t('dictionary.you'))
    followers_description = I18n.t('searches.common_followers.description', user: sn, login: I18n.t('dictionary.you'))

    if h.search_oneself?(object.uid)
      [
        {
          name: friends_name,
          description: friends_description,
          target: [],
          path: h.common_friends_path(screen_name: object.screen_name)
        }, {
          name: followers_name,
          description: followers_description,
          target: [],
          path: h.common_followers_path(screen_name: object.screen_name)
        },
      ]
    elsif h.search_others?(object.uid)
      current_user_tu = h.current_user.twitter_user
      [
        {
          name: friends_name,
          description: friends_description,
          target: object.common_friends(current_user_tu),
          graph: object.common_friends_graph(current_user_tu),
          path: h.common_friends_path(screen_name: object.screen_name)
        }, {
          name: followers_name,
          description: followers_description,
          target: object.common_followers(current_user_tu),
          graph: object.common_followers_graph(current_user_tu),
          path: h.common_followers_path(screen_name: object.screen_name)
        },
      ]
    elsif !h.user_signed_in?
      [
        {
          name: friends_name,
          description: friends_description,
          target: [],
          path: h.common_friends_path(screen_name: object.screen_name)
        }, {
          name: followers_name,
          description: followers_description,
          target: [],
          path: h.common_followers_path(screen_name: object.screen_name)
        },
      ]
    end
  end
end
