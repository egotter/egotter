module FunctionsSectionHelper
  def function_one_sided_friends_values
    if user_signed_in?
      url = one_sided_friend_path(screen_name: current_user.screen_name, via: build_via('functions_button'))
      button = link_to t('shared.functions.analyze', user: current_user.screen_name), url, class: 'btn btn-primary btn-block'

      url = one_sided_friend_path(screen_name: current_user.screen_name, via: build_via('functions_user_name'))
      name = t('shared.functions.me_html', user: current_user.screen_name, url: url)
    else
      url = one_sided_friends_top_path(via: build_via('functions_button'))
      button = sign_in_with_twitter_link(url, build_via('functions_button'), class: 'btn btn-primary btn-block')
      name = t('shared.functions.visitor')
    end


    {
        path: one_sided_friends_top_path(via: build_via('functions_icon')),
        title: t('shared.functions.one_sided_friends.title'),
        what_is_this: t('shared.functions.one_sided_friends.what_is_this_html', user: name),
        description: t('shared.functions.one_sided_friends.text_html',
                       title: strip_tags(t('shared.functions.one_sided_friends.title')),
                       user: name,
                       url: one_sided_friends_top_path(via: build_via('functions_description'))
        ),
        button: button,
        image: '/egotter_onesided_friends_with_text_400x453.png'
    }
  end

  def function_unfriends_values
    if user_signed_in?
      url = unfriend_path(screen_name: current_user.screen_name, via: build_via('functions_button'))
      button = link_to t('shared.functions.analyze', user: current_user.screen_name), url, class: 'btn btn-primary btn-block'

      url = unfriend_path(screen_name: current_user.screen_name, via: build_via('functions_user_name'))
      name = t('shared.functions.me_html', user: current_user.screen_name, url: url)
    else
      url = unfriends_top_path(via: build_via('functions_button'))
      button = sign_in_with_twitter_link(url, build_via('functions_button'), class: 'btn btn-primary btn-block')
      name = t('shared.functions.visitor')
    end

    {
        path: unfriends_top_path(via: build_via('functions_icon')),
        title: t('shared.functions.unfriends.title'),
        what_is_this: t('shared.functions.unfriends.what_is_this_html', user: name),
        description: t('shared.functions.unfriends.text_html',
                       title: strip_tags(t('shared.functions.unfriends.title')),
                       user: name,
                       url: unfriends_top_path(via: build_via('functions_description'))
        ),
        button: button,
        image: '/egotter_unfriends_with_text_400x453.png'
    }
  end

  def function_inactive_friends_values
    if user_signed_in?
      url = inactive_friend_path(screen_name: current_user.screen_name, via: build_via('functions_button'))
      button = link_to t('shared.functions.analyze', user: current_user.screen_name), url, class: 'btn btn-primary btn-block'

      url = inactive_friend_path(screen_name: current_user.screen_name, via: build_via('functions_user_name'))
      name = t('shared.functions.me_html', user: current_user.screen_name, url: url)
    else
      url = inactive_friends_top_path(via: build_via('functions_button'))
      button = sign_in_with_twitter_link(url, build_via('functions_button'), class: 'btn btn-primary btn-block')
      name = t('shared.functions.visitor')
    end

    {
        path: inactive_friends_top_path(via: build_via('functions_icon')),
        title: t('shared.functions.inactive_friends.title'),
        what_is_this: t('shared.functions.inactive_friends.what_is_this_html', user: name),
        description: t('shared.functions.inactive_friends.text_html',
                       title: strip_tags(t('shared.functions.inactive_friends.title')),
                       user: name,
                       url: inactive_friends_top_path(via: build_via('functions_description'))
        ),
        button: button,
        image: '/egotter_inactive_friends_with_text_400x453.png'
    }
  end

  def function_friends_values
    if user_signed_in?
      url = friend_path(screen_name: current_user.screen_name, via: build_via('functions_button'))
      button = link_to t('shared.functions.analyze', user: current_user.screen_name), url, class: 'btn btn-primary btn-block'

      url = friend_path(screen_name: current_user.screen_name, via: build_via('functions_user_name'))
      name = t('shared.functions.me_html', user: current_user.screen_name, url: url)
    else
      url = friends_top_path(via: build_via('functions_button'))
      button = sign_in_with_twitter_link(url, build_via('functions_button'), class: 'btn btn-primary btn-block')
      name = t('shared.functions.visitor')
    end

    {
        path: friends_top_path(via: build_via('functions_icon')),
        title: t('shared.functions.friends.title'),
        what_is_this: t('shared.functions.friends.what_is_this_html', user: name),
        description: t('shared.functions.friends.text_html',
                       title: strip_tags(t('shared.functions.friends.title')),
                       user: name,
                       url: friends_top_path(via: build_via('functions_description'))
        ),
        button: button,
        image: '/egotter_friends_with_text_400x453.png'
    }
  end

  def function_clusters_values
    if user_signed_in?
      url = cluster_path(screen_name: current_user.screen_name, via: build_via('functions_button'))
      button = link_to t('shared.functions.analyze', user: current_user.screen_name), url, class: 'btn btn-primary btn-block'
    else
      url = clusters_top_path(via: build_via('functions_button'))
      button = sign_in_with_twitter_link(url, build_via('functions_button'), class: 'btn btn-primary btn-block')
    end

    {
        path: clusters_top_path(via: build_via('functions_icon')),
        title: t('shared.functions.clusters.title'),
        what_is_this: t('shared.functions.clusters.what_is_this_html'),
        description: t('shared.functions.clusters.text_html',
                       title: strip_tags(t('shared.functions.clusters.title')),
                       url: clusters_top_path(via: build_via('functions_description'))
        ),
        button: button,
        image: '/egotter_clusters_with_text_400x453.png'
    }
  end

  def function_tokimeki_unfollow_values
    if user_signed_in?
      url = tokimeki_unfollow_top_path(via: build_via('functions_button'))
      button = link_to t('shared.functions.analyze', user: current_user.screen_name), url, class: 'btn btn-primary btn-block'
    else
      url = tokimeki_unfollow_top_path(via: build_via('functions_button'))
      button = sign_in_with_twitter_link(url, build_via('functions_button'), class: 'btn btn-primary btn-block')
    end

    {
        path: tokimeki_unfollow_top_path(via: build_via('functions_icon')),
        title: t('shared.functions.tokimeki_unfollow.title'),
        what_is_this: t('shared.functions.tokimeki_unfollow.what_is_this_html'),
        description: t('shared.functions.tokimeki_unfollow.text_html',
                       title: strip_tags(t('shared.functions.tokimeki_unfollow.title')),
                       url: tokimeki_unfollow_top_path(via: build_via('functions_description'))
        ),
        button: button,
        image: '/egotter_tokimeki_unfollow_with_text_400x453.png'
    }
  end

  def function_delete_tweets_values
    if user_signed_in?
      url = delete_tweets_path(via: build_via('functions_button'))
      button = link_to t('shared.functions.analyze', user: current_user.screen_name), url, class: 'btn btn-primary btn-block'
    else
      url = delete_tweets_path(via: build_via('functions_button'))
      button = sign_in_with_twitter_link(url, build_via('functions_button'), class: 'btn btn-primary btn-block')
    end

    {
        path: delete_tweets_path(via: build_via('functions_icon')),
        title: t('shared.functions.delete_tweets.title'),
        what_is_this: t('shared.functions.delete_tweets.what_is_this_html'),
        description: t('shared.functions.delete_tweets.text_html',
                       title: strip_tags(t('shared.functions.delete_tweets.title')),
                       url: delete_tweets_path(via: build_via('functions_description'))
        ),
        button: button,
        image: '/egotter_delete_tweets_with_text_400x453.png'
    }
  end
end
