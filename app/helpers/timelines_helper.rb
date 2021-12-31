module TimelinesHelper
  def feed_attrs(name, twitter_user)
    attrs = {
        feed_name: name,
        page_url: feed_page_path(name, twitter_user),
        api_url: api_summary_path(name, twitter_user),
        twitter_user: twitter_user,
    }

    case name
    when 'close_friends'
      attrs.merge(
          feed_title: t('timelines.feeds.close_friends.title'),
          feed_description: t('timelines.feeds.close_friends.description', user: twitter_user.screen_name),
      )
    when 'unfriends'
      attrs.merge(
          feed_title: t('timelines.feeds.unfriends.title'),
          feed_description: t('timelines.feeds.unfriends.description', user: twitter_user.screen_name),
      )
    when 'unfollowers'
      attrs.merge(
          feed_title: t('timelines.feeds.unfollowers.title'),
          feed_description: t('timelines.feeds.unfollowers.description', user: twitter_user.screen_name),
      )
    when 'mutual_unfriends'
      attrs.merge(
          feed_title: t('timelines.feeds.mutual_unfriends.title'),
          feed_description: t('timelines.feeds.mutual_unfriends.description', user: twitter_user.screen_name),
      )
    when 'blockers'
      raise 'The attributes of blockers are embedded directly'
    when 'muters'
      raise 'The attributes of muters are embedded directly'
    when 'mutual_friends'
      attrs.merge(
          feed_title: t('timelines.feeds.mutual_friends.title'),
          feed_description: t('timelines.feeds.mutual_friends.description', user: twitter_user.screen_name),
      )
    when 'one_sided_friends'
      attrs.merge(
          feed_title: t('timelines.feeds.one_sided_friends.title'),
          feed_description: t('timelines.feeds.one_sided_friends.description', user: twitter_user.screen_name),
      )
    when 'one_sided_followers'
      attrs.merge(
          feed_title: t('timelines.feeds.one_sided_followers.title'),
          feed_description: t('timelines.feeds.one_sided_followers.description', user: twitter_user.screen_name),
      )
    when 'replying'
      attrs.merge(
          feed_title: t('timelines.feeds.replying.title'),
          feed_description: t('timelines.feeds.replying.description', user: twitter_user.screen_name),
      )
    when 'replied'
      attrs.merge(
          feed_title: t('timelines.feeds.replied.title'),
          feed_description: t('timelines.feeds.replied.description', user: twitter_user.screen_name),
      )
    when 'favorite_friends'
      attrs.merge(
          feed_title: t('timelines.feeds.favorite_friends.title'),
          feed_description: t('timelines.feeds.favorite_friends.description', user: twitter_user.screen_name),
      )
    when 'inactive_friends'
      attrs.merge(
          feed_title: t('timelines.feeds.inactive_friends.title'),
          feed_description: t('timelines.feeds.inactive_friends.description', user: twitter_user.screen_name),
      )
    when 'inactive_followers'
      attrs.merge(
          feed_title: t('timelines.feeds.inactive_followers.title'),
          feed_description: t('timelines.feeds.inactive_followers.description', user: twitter_user.screen_name),
      )
    when 'common_friends'
      attrs.merge(
          feed_title: t('timelines.feeds.common_friends.title'),
          feed_description: t('timelines.feeds.common_friends.description', user1: twitter_user.screen_name, user2: current_user.screen_name),
      )
    when 'common_followers'
      attrs.merge(
          feed_title: t('timelines.feeds.common_followers.title'),
          feed_description: t('timelines.feeds.common_followers.description', user1: twitter_user.screen_name, user2: current_user.screen_name),
      )
    else
      raise "Invalid name value=#{name}"
    end
  end
end
