class CommonFollowersController < ::Page::CommonFriendsAndCommonFollowers

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
      common_friends: @twitter_user.common_friend_uids(current_user.twitter_user).size,
      common_followers: @twitter_user.common_follower_uids(current_user.twitter_user).size,
      common_mutual_friends: @twitter_user.common_mutual_friend_uids(current_user.twitter_user).size
    }
  end

  def tabs
    [
      {text: t('common_friends.show.see_common_friends_html', num: @twitter_user.common_friend_uids(current_user.twitter_user).size), url: common_friend_path(@twitter_user)},
      {text: t('common_friends.show.see_common_followers_html', num: @twitter_user.common_follower_uids(current_user.twitter_user).size), url: common_follower_path(@twitter_user)},
      {text: t('common_friends.show.see_common_mutual_friends_html', num: @twitter_user.common_mutual_friend_uids(current_user.twitter_user).size), url: common_mutual_friend_path(@twitter_user)}
    ]
  end
end
