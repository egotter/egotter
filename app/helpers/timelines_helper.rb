module TimelinesHelper
  def summary_description(name)
    case name
    when 'one_sided_friends'
      t('timelines.feeds.summary.description.one_sided_friends')
    when 'one_sided_followers'
      t('timelines.feeds.summary.description.one_sided_followers')
    when 'mutual_friends'
      t('timelines.feeds.summary.description.mutual_friends')
    when 'unfriends'
      t('timelines.feeds.summary.description.unfriends')
    when 'unfollowers'
      t('timelines.feeds.summary.description.unfollowers')
    when 'blocking_or_blocked'
      t('timelines.feeds.summary.description.blocking_or_blocked')
    else
      raise "Invalid name value=#{name}"
    end
  end
end
