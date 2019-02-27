class FollowersController < FriendsAndFollowers
  def all
    super
    render template: 'friends/all' unless performed?
  end

  def show
    super
    @active_tab = 1
    render template: 'friends/show' unless performed?
  end

  private

  def related_counts
    {
      followers: @twitter_user.follower_uids.size,
      one_sided_followers: @twitter_user.one_sided_followerships.size,
      one_sided_followers_rate: (@twitter_user.one_sided_followers_rate * 100).round(1)
    }
  end

  def tabs
    [
      {text: t('friends.show.see_friends_html', num: @twitter_user.friend_uids.size), url: friend_path(@twitter_user)},
      {text: t('friends.show.see_followers_html', num: @twitter_user.follower_uids.size), url: follower_path(@twitter_user)}
    ]
  end
end
