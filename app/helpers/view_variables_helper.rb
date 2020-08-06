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

  def current_meta_title(twitter_user)
    raise NotImplementedError
  end

  def current_meta_description(twitter_user)
    if controller_name == 'statuses'
      return t('meta_descriptions.statuses', user: twitter_user.screen_name)
    elsif controller_name == 'close_friends'
      return t('meta_descriptions.close_friends', user: twitter_user.screen_name)
    elsif controller_name == 'favorite_friends'
      return t('meta_descriptions.favorite_friends', user: twitter_user.screen_name)
    end

    values = {user: twitter_user.screen_name}.merge(current_counts(twitter_user))

    case controller_name
    when 'friends'
      t('meta_descriptions.friends', values)
    when 'followers'
      t('meta_descriptions.followers', values)
    when 'unfriends'
      t('meta_descriptions.unfriends', values)
    when 'unfollowers'
      t('meta_descriptions.unfollowers', values)
    when 'blocking_or_blocked'
      t('meta_descriptions.blocking_or_blocked', values)
    when 'close_friends'
      t('meta_descriptions.close_friends', values)
    when 'favorite_friends'
      t('meta_descriptions.favorite_friends', values)
    when 'one_sided_friends'
      t('meta_descriptions.one_sided_friends', values)
    when 'one_sided_followers'
      t('meta_descriptions.one_sided_followers', values)
    when 'mutual_friends'
      t('meta_descriptions.mutual_friends', values)
    when 'inactive_friends'
      t('meta_descriptions.inactive_friends', values)
    when 'inactive_followers'
      t('meta_descriptions.inactive_followers', values)
    when 'inactive_mutual_friends'
      t('meta_descriptions.inactive_mutual_friends', values)
    when 'replying'
      t('meta_descriptions.replying', values)
    when 'replied'
      t('meta_descriptions.replied', values)
    when 'replying_and_replied'
      t('meta_descriptions.replying_and_replied', values)
    when 'common_friends'
      t('meta_descriptions.common_friends', values.merge(user2: current_user.screen_name))
    when 'common_followers'
      t('meta_descriptions.common_followers', values.merge(user2: current_user.screen_name))
    when 'common_mutual_friends'
      t('meta_descriptions.common_mutual_friends', values.merge(user2: current_user.screen_name))
    else
      raise "Invalid controller value=#{controller_name}"
    end
  end
end
