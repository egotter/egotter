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
    when 'mutual_unfriends'
      t('timelines.feeds.summary.description.mutual_unfriends')
    else
      raise "Invalid name value=#{name}"
    end
  end
end
