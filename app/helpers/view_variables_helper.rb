module ViewVariablesHelper
  def current_page_title(twitter_user)
    name = twitter_user.screen_name

    case controller_name
    when 'statuses'
      t('page_titles.statuses', user: name)
    when 'friends'
      t('page_titles.friends', user: name)
    when 'followers'
      t('page_titles.followers', user: name)
    when 'unfriends'
      t('page_titles.unfriends', user: name)
    when 'unfollowers'
      t('page_titles.unfollowers', user: name)
    when 'blocking_or_blocked'
      t('page_titles.blocking_or_blocked', user: name)
    when 'close_friends'
      t('page_titles.close_friends', user: name)
    when 'favorite_friends'
      t('page_titles.favorite_friends', user: name)
    when 'one_sided_friends'
      t('page_titles.one_sided_friends', user: name)
    when 'one_sided_followers'
      t('page_titles.one_sided_followers', user: name)
    when 'mutual_friends'
      t('page_titles.mutual_friends', user: name)
    when 'inactive_friends'
      t('page_titles.inactive_friends', user: name)
    when 'inactive_followers'
      t('page_titles.inactive_followers', user: name)
    when 'inactive_mutual_friends'
      t('page_titles.inactive_mutual_friends', user: name)
    when 'replying'
      t('page_titles.replying', user: name)
    when 'replied'
      t('page_titles.replied', user: name)
    when 'replying_and_replied'
      t('page_titles.replying_and_replied', user: name)
    when 'common_friends'
      t('page_titles.common_friends', user: name, user2: current_user.screen_name)
    when 'common_followers'
      t('page_titles.common_followers', user: name, user2: current_user.screen_name)
    when 'common_mutual_friends'
      t('page_titles.common_mutual_friends', user: name, user2: current_user.screen_name)
    else
      raise "Invalid controller value=#{controller_name}"
    end
  end

  def current_content_title(twitter_user)
    case controller_name
    when 'unfollowers'
      t('content_titles.unfollowers', user: twitter_user.screen_name)
    else
      current_page_title(twitter_user)
    end
  end
end
