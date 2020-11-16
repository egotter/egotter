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
    when 'mutual_unfriends'
      t('page_titles.mutual_unfriends', user: name)
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
    when 'mutual_unfriends'
      t('meta_descriptions.mutual_unfriends', values)
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

  def current_page_description(twitter_user, tag_id: 'hidden-page-description')
    values = {
        user: timeline_link(twitter_user),
        tag_id: tag_id,
        url: subroot_path
    }

    case controller_name
    when 'statuses'
      t('page_descriptions.statuses_html', values)
    when 'friends'
      t('page_descriptions.friends_html', values)
    when 'followers'
      t('page_descriptions.followers_html', values)
    when 'unfriends'
      render template: 'page_descriptions/unfriends', locals: {twitter_user: twitter_user}
    when 'unfollowers'
      render template: 'page_descriptions/unfollowers', locals: {twitter_user: twitter_user}
    when 'mutual_unfriends'
      render template: 'page_descriptions/mutual_unfriends', locals: {twitter_user: twitter_user}
    when 'close_friends'
      t('page_descriptions.close_friends_html', values)
    when 'favorite_friends'
      t('page_descriptions.favorite_friends_html', values)
    when 'one_sided_friends'
      t('page_descriptions.one_sided_friends_html', values)
    when 'one_sided_followers'
      t('page_descriptions.one_sided_followers_html', values)
    when 'mutual_friends'
      t('page_descriptions.mutual_friends_html', values)
    when 'inactive_friends'
      t('page_descriptions.inactive_friends_html', values)
    when 'inactive_followers'
      t('page_descriptions.inactive_followers_html', values)
    when 'inactive_mutual_friends'
      t('page_descriptions.inactive_mutual_friends_html', values)
    when 'replying'
      t('page_descriptions.replying_html', values)
    when 'replied'
      t('page_descriptions.replied_html', values)
    when 'replying_and_replied'
      t('page_descriptions.replying_and_replied_html', values)
    when 'common_friends'
      t('page_descriptions.common_friends_html', values.merge(user2: timeline_link(current_user)))
    when 'common_followers'
      t('page_descriptions.common_followers_html', values.merge(user2: timeline_link(current_user)))
    when 'common_mutual_friends'
      t('page_descriptions.common_mutual_friends_html', values.merge(user2: timeline_link(current_user)))
    else
      raise "Invalid controller value=#{controller_name}"
    end.html_safe
  end

  def current_navbar_title
    case controller_name
    when 'statuses'
      t('navbar_titles.statuses')
    when 'friends'
      t('navbar_titles.friends')
    when 'followers'
      t('navbar_titles.followers')
    when 'unfriends'
      t('navbar_titles.unfriends')
    when 'unfollowers'
      t('navbar_titles.unfollowers')
    when 'mutual_unfriends'
      t('navbar_titles.mutual_unfriends')
    when 'close_friends'
      t('navbar_titles.close_friends')
    when 'favorite_friends'
      t('navbar_titles.favorite_friends')
    when 'one_sided_friends'
      t('navbar_titles.one_sided_friends')
    when 'one_sided_followers'
      t('navbar_titles.one_sided_followers')
    when 'mutual_friends'
      t('navbar_titles.mutual_friends')
    when 'inactive_friends'
      t('navbar_titles.inactive_friends')
    when 'inactive_followers'
      t('navbar_titles.inactive_followers')
    when 'inactive_mutual_friends'
      t('navbar_titles.inactive_mutual_friends')
    when 'replying'
      t('navbar_titles.replying')
    when 'replied'
      t('navbar_titles.replied')
    when 'replying_and_replied'
      t('navbar_titles.replying_and_replied')
    when 'common_friends'
      t('navbar_titles.common_friends')
    when 'common_followers'
      t('navbar_titles.common_followers')
    when 'common_mutual_friends'
      t('navbar_titles.common_mutual_friends')
    else
      raise "Invalid controller value=#{controller_name}"
    end
  end

  def current_crumb_title
    case controller_name
    when 'statuses'
      t('crumb_titles.statuses')
    when 'friends'
      t('crumb_titles.friends')
    when 'followers'
      t('crumb_titles.followers')
    when 'unfriends'
      t('crumb_titles.unfriends')
    when 'unfollowers'
      t('crumb_titles.unfollowers')
    when 'mutual_unfriends'
      t('crumb_titles.mutual_unfriends')
    when 'close_friends'
      t('crumb_titles.close_friends')
    when 'favorite_friends'
      t('crumb_titles.favorite_friends')
    when 'one_sided_friends'
      t('crumb_titles.one_sided_friends')
    when 'one_sided_followers'
      t('crumb_titles.one_sided_followers')
    when 'mutual_friends'
      t('crumb_titles.mutual_friends')
    when 'inactive_friends'
      t('crumb_titles.inactive_friends')
    when 'inactive_followers'
      t('crumb_titles.inactive_followers')
    when 'inactive_mutual_friends'
      t('crumb_titles.inactive_mutual_friends')
    when 'replying'
      t('crumb_titles.replying')
    when 'replied'
      t('crumb_titles.replied')
    when 'replying_and_replied'
      t('crumb_titles.replying_and_replied')
    when 'common_friends'
      t('crumb_titles.common_friends')
    when 'common_followers'
      t('crumb_titles.common_followers')
    when 'common_mutual_friends'
      t('crumb_titles.common_mutual_friends')
    else
      raise "Invalid controller value=#{controller_name}"
    end
  end

  def current_breadcrumb(user)
    breadcrumb controller_name.singularize.to_sym, user.screen_name
  end

  def current_canonical_url(twitter_user)
    send("#{controller_name.singularize}_url", twitter_user)
  end

  def current_tweet_text(twitter_user)
    values = {user: twitter_user.screen_name, url: current_canonical_url(twitter_user)}.merge(current_counts(twitter_user))

    case controller_name
    when 'friends'
      user = TwitterUserDecorator.new(twitter_user)
      t('tweet_text.friends', values.merge(reverse_follow_back_rate: user.reverse_percent_follow_back_rate, follow_back_rate: user.percent_follow_back_rate))
    when 'followers'
      user = TwitterUserDecorator.new(twitter_user)
      t('tweet_text.followers', values.merge(reverse_follow_back_rate: user.reverse_percent_follow_back_rate, follow_back_rate: user.percent_follow_back_rate))
    when 'unfriends'
      users = twitter_user.unfriends(limit: 3).map { |user| "@#{user.screen_name} #{t('dictionary.honorific')}" }
      t('tweet_text.unfriends', values.merge(users: users.join("\n")))
    when 'unfollowers'
      users = twitter_user.unfollowers(limit: 3).map { |user| "@#{user.screen_name} #{t('dictionary.honorific')}" }
      t('tweet_text.unfollowers', values.merge(users: users.join("\n")))
    when 'mutual_unfriends'
      users = twitter_user.mutual_unfriends(limit: 3).map { |user| "@#{user.screen_name} #{t('dictionary.honorific')}" }
      t('tweet_text.mutual_unfriends', values.merge(users: users.join("\n")))
    when 'close_friends'
      users = twitter_user.close_friends(limit: 5).map.with_index { |u, i| "#{i + 1}. @#{u.screen_name}" }
      t('tweet_text.close_friends', values.merge(users: users.join("\n")))
    when 'favorite_friends'
      users = twitter_user.favorite_friends(limit: 5).map.with_index { |u, i| "#{i + 1}. @#{u.screen_name}" }
      t('tweet_text.favorite_friends', values.merge(users: users.join("\n")))
    when 'one_sided_friends'
      t('tweet_text.one_sided_friends', values)
    when 'one_sided_followers'
      t('tweet_text.one_sided_followers', values)
    when 'mutual_friends'
      t('tweet_text.mutual_friends', values)
    when 'inactive_friends'
      t('tweet_text.inactive_friends', values)
    when 'inactive_followers'
      t('tweet_text.inactive_followers', values)
    when 'inactive_mutual_friends'
      t('tweet_text.inactive_mutual_friends', values)
    when 'replying'
      t('tweet_text.replying', values)
    when 'replied'
      t('tweet_text.replied', values)
    when 'replying_and_replied'
      t('tweet_text.replying_and_replied', values)
    when 'common_friends'
      t('tweet_text.common_friends', values.merge(user2: current_user.twitter_user.screen_name))
    when 'common_followers'
      t('tweet_text.common_followers', values.merge(user2: current_user.twitter_user.screen_name))
    when 'common_mutual_friends'
      t('tweet_text.common_mutual_friends', values.merge(user2: current_user.twitter_user.screen_name))
    else
      raise "Invalid controller value=#{controller_name}"
    end
  end

  def trends_word_cloud_description(trend)
    trend = TrendDecorator.new(trend)
    t('word_cloud_descriptions.trends_html', url: trend.search_url, time: trend.elapsed_time, name: trend.name, rank: trend.rank)
  end

  def trends_times_count_description(trend)
    trend = TrendDecorator.new(trend)
    t('times_count_descriptions.trends_html', url: trend.search_url, time: trend.elapsed_time, name: trend.name, count: trend.tweets_count)
  end

  def profiles_word_cloud_description(twitter_user)
    case controller_name
    when 'friends'
      t('word_cloud_descriptions.friend_profiles', user: twitter_user.screen_name)
    when 'followers'
      t('word_cloud_descriptions.follower_profiles', user: twitter_user.screen_name)
    else
      raise "Invalid controller value=#{controller_name}"
    end
  end

  def locations_word_cloud_description(twitter_user)
    case controller_name
    when 'friends'
      t('word_cloud_descriptions.friend_locations', user: twitter_user.screen_name)
    when 'followers'
      t('word_cloud_descriptions.follower_locations', user: twitter_user.screen_name)
    else
      raise "Invalid controller value=#{controller_name}"
    end
  end

  def tweets_per_hour_description(twitter_user)
    case controller_name
    when 'friends'
      t('tweets_per_hour_description.friends', user: twitter_user.screen_name)
    when 'followers'
      t('tweets_per_hour_description.followers', user: twitter_user.screen_name)
    else
      raise "Invalid controller value=#{controller_name}"
    end
  end

  private

  def timeline_link(user)
    link_to('@' + user.screen_name, timeline_path(user, via: current_via('page_description')))
  end
end
