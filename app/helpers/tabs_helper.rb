module TabsHelper
  def current_tabs(twitter_user)
    case controller_name
    when 'friends', 'followers'
      friends_tabs(twitter_user)
    when 'unfriends', 'unfollowers', 'blocking_or_blocked'
      unfriends_tabs(twitter_user)
    when 'close_friends', 'favorite_friends'
      close_friends_tabs(twitter_user)
    when 'one_sided_friends', 'one_sided_followers', 'mutual_friends'
      one_sided_friends_tabs(twitter_user)
    when 'inactive_friends', 'inactive_followers', 'inactive_mutual_friends'
      inactive_friends_tabs(twitter_user)
    when 'replying', 'replied', 'replying_and_replied'
      replying_tabs(twitter_user)
    when 'common_friends', 'common_followers', 'common_mutual_friends'
      common_friends_tabs(twitter_user)
    else
      raise "Invalid controller value=#{controller_name}"
    end
  end

  def friends_tabs(user)
    [
        Tab.new(t('tabs.friends'), user.friend_uids.size, friend_path(user, via: current_via('tab'))),
        Tab.new(t('tabs.followers'), user.follower_uids.size, follower_path(user, via: current_via('tab')))
    ]
  end

  def unfriends_tabs(user)
    [
        Tab.new(t('tabs.unfriends'), user.unfriendships.size, unfriend_path(user, via: current_via('tab'))),
        Tab.new(t('tabs.unfollowers'), user.unfollowerships.size, unfollower_path(user, via: current_via('tab'))),
        Tab.new(t('tabs.blocking_or_blocked'), user.mutual_unfriendships.size, blocking_or_blocked_path(user, via: current_via('tab')))
    ]
  end

  def close_friends_tabs(user)
    [
        Tab.new(t('tabs.close_friends'), user.close_friendships.size, close_friend_path(user, via: current_via('tab'))),
        Tab.new(t('tabs.favorite_friends'), user.favorite_friendships.size, favorite_friend_path(user, via: current_via('tab')))
    ]
  end

  def one_sided_friends_tabs(user)
    [
        Tab.new(t('tabs.one_sided_friends'), user.one_sided_friendships.size, one_sided_friend_path(user, via: current_via('tab'))),
        Tab.new(t('tabs.one_sided_followers'), user.one_sided_followerships.size, one_sided_follower_path(user, via: current_via('tab'))),
        Tab.new(t('tabs.mutual_friends'), user.mutual_friendships.size, mutual_friend_path(user, via: current_via('tab')))
    ]
  end

  def inactive_friends_tabs(user)
    [
        Tab.new(t('tabs.inactive_friends'), user.inactive_friendships.size, inactive_friend_path(user, via: current_via('tab'))),
        Tab.new(t('tabs.inactive_followers'), user.inactive_followerships.size, inactive_follower_path(user, via: current_via('tab'))),
        Tab.new(t('tabs.inactive_mutual_friends'), user.inactive_mutual_friendships.size, inactive_mutual_friend_path(user, via: current_via('tab')))
    ]
  end

  def replying_tabs(user)
    [
        Tab.new(t('tabs.replying'), user.replying_uids.size, replying_path(user, via: current_via('tab'))),
        Tab.new(t('tabs.replied'), user.replied_uids.size, replied_path(user, via: current_via('tab'))),
        Tab.new(t('tabs.replying_and_replied'), user.replying_and_replied_uids.size, replying_and_replied_path(user, via: current_via('tab')))
    ]
  end

  def common_friends_tabs(user)
    [
        Tab.new(t('tabs.common_friends'), user.common_friend_uids(current_user.twitter_user).size, common_friend_path(user, via: current_via('tab'))),
        Tab.new(t('tabs.common_followers'), user.common_follower_uids(current_user.twitter_user).size, common_follower_path(user, via: current_via('tab'))),
        Tab.new(t('tabs.common_mutual_friends'), user.common_mutual_friend_uids(current_user.twitter_user).size, common_mutual_friend_path(user, via: current_via('tab')))
    ]
  end

  def current_counts(twitter_user)
    counts = current_tabs(twitter_user).map(&:count)

    case controller_name
    when 'friends', 'followers'
      %i(friends followers).zip(counts).to_h
    when 'unfriends', 'unfollowers', 'blocking_or_blocked'
      %i(unfriends unfollowers blocking_or_blocked).zip(counts).to_h
    when 'close_friends', 'favorite_friends'
      %i(close_friends favorite_friends).zip(counts).to_h
    when 'one_sided_friends', 'one_sided_followers', 'mutual_friends'
      %i(one_sided_friends one_sided_followers mutual_friends).zip(counts).to_h
    when 'inactive_friends', 'inactive_followers', 'inactive_mutual_friends'
      %i(inactive_friends inactive_followers inactive_mutual_friends).zip(counts).to_h
    when 'replying', 'replied', 'replying_and_replied'
      %i(replying replied replying_and_replied).zip(counts).to_h
    when 'common_friends', 'common_followers', 'common_mutual_friends'
      %i(common_friends common_followers common_mutual_friends).zip(counts).to_h
    else
      raise "Invalid controller value=#{controller_name}"
    end
  end
end
