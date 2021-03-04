module TimelinesHelper
  def summary_description(name)
    case name
    when 'one_sided_friends'
      t('timelines.feeds.summary.description.one_sided_friends')
    when 'one_sided_followers'
      t('timelines.feeds.summary.description.one_sided_followers')
    when 'mutual_friends'
      t('timelines.feeds.summary.description.mutual_friends')
    when 'inactive_friends'
      t('timelines.feeds.summary.description.inactive_friends')
    when 'inactive_followers'
      t('timelines.feeds.summary.description.inactive_followers')
    when 'unfriends'
      t('timelines.feeds.summary.description.unfriends')
    when 'unfollowers'
      t('timelines.feeds.summary.description.unfollowers')
    when 'mutual_unfriends'
      t('timelines.feeds.summary.description.mutual_unfriends')
    when 'blockers'
      t('timelines.feeds.summary.description.blockers')
    when 'muters'
      t('timelines.feeds.summary.description.muters')
    else
      raise "Invalid name value=#{name}"
    end
  end

  def feed_attrs(name, twitter_user)
    case name
    when 'close_friends'
      attrs = {
          feed_title: t('timelines.feeds.close_friends.title'),
          feed_description: t('timelines.feeds.close_friends.description', user: twitter_user.screen_name),
      }
    when 'unfriends'
      attrs = {
          feed_title: t('timelines.feeds.unfriends.title'),
          feed_description: t('timelines.feeds.unfriends.description', user: twitter_user.screen_name),
      }
    when 'unfollowers'
      attrs = {
          feed_title: t('timelines.feeds.unfollowers.title'),
          feed_description: t('timelines.feeds.unfollowers.description', user: twitter_user.screen_name),
      }
    when 'mutual_unfriends'
      attrs = {
          feed_title: t('timelines.feeds.mutual_unfriends.title'),
          feed_description: t('timelines.feeds.mutual_unfriends.description', user: twitter_user.screen_name),
      }
    when 'blockers'
      attrs = {
          feed_title: t('timelines.feeds.blockers.title'),
          feed_description: t('timelines.feeds.blockers.description', user: twitter_user.screen_name),
      }
    when 'muters'
      attrs = {
          feed_title: t('timelines.feeds.muters.title'),
          feed_description: t('timelines.feeds.muters.description_html', user: twitter_user.screen_name, count: twitter_user.muters_size),
      }
    when 'mutual_friends'
      attrs = {
          feed_title: t('timelines.feeds.mutual_friends.title'),
          feed_description: t('timelines.feeds.mutual_friends.description', user: twitter_user.screen_name),
      }
    when 'one_sided_friends'
      attrs = {
          feed_title: t('timelines.feeds.one_sided_friends.title'),
          feed_description: t('timelines.feeds.one_sided_friends.description', user: twitter_user.screen_name),
      }
    when 'one_sided_followers'
      attrs = {
          feed_title: t('timelines.feeds.one_sided_followers.title'),
          feed_description: t('timelines.feeds.one_sided_followers.description', user: twitter_user.screen_name),
      }
    when 'replying'
      attrs = {
          feed_title: t('timelines.feeds.replying.title'),
          feed_description: t('timelines.feeds.replying.description', user: twitter_user.screen_name),
      }
    when 'replied'
      attrs = {
          feed_title: t('timelines.feeds.replied.title'),
          feed_description: t('timelines.feeds.replied.description', user: twitter_user.screen_name),
      }
    when 'favorite_friends'
      attrs = {
          feed_title: t('timelines.feeds.favorite_friends.title'),
          feed_description: t('timelines.feeds.favorite_friends.description', user: twitter_user.screen_name),
      }
    when 'inactive_friends'
      attrs = {
          feed_title: t('timelines.feeds.inactive_friends.title'),
          feed_description: t('timelines.feeds.inactive_friends.description', user: twitter_user.screen_name),
      }
    when 'inactive_followers'
      attrs = {
          feed_title: t('timelines.feeds.inactive_followers.title'),
          feed_description: t('timelines.feeds.inactive_followers.description', user: twitter_user.screen_name),
      }
    when 'common_friends'
      attrs = {
          feed_title: t('timelines.feeds.common_friends.title'),
          feed_description: t('timelines.feeds.common_friends.description', user1: twitter_user.screen_name, user2: current_user.screen_name),
      }
    when 'common_followers'
      attrs = {
          feed_title: t('timelines.feeds.common_followers.title'),
          feed_description: t('timelines.feeds.common_followers.description', user1: twitter_user.screen_name, user2: current_user.screen_name),
      }
    else
      raise "Invalid name value=#{name}"
    end

    attrs.merge(
        feed_name: name,
        page_url: feed_page_path(name, twitter_user),
        api_url: api_summary_path(name, twitter_user),
        twitter_user: twitter_user,
    )
  end
end
