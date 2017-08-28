class MutualFriendsController < FriendsAndFollowers

  def all
    super
    render template: 'friends/all' unless performed?
  end

  def show
    super
    @active_tab = 2
    render template: 'friends/show' unless performed?
  end

  private

  def related_counts
    {
      one_sided_friends: @twitter_user.one_sided_friendships.size,
      one_sided_followers: @twitter_user.one_sided_followerships.size,
      mutual_friends: @twitter_user.mutual_friendships.size
    }
  end

  def tabs
    [
      {text: t('one_sided_friends.show.see_one_sided_friends_html', num: @twitter_user.one_sided_friendships.size), url: one_sided_friend_path(@twitter_user)},
      {text: t('one_sided_friends.show.see_one_sided_followers_html', num: @twitter_user.one_sided_followerships.size), url: one_sided_follower_path(@twitter_user)},
      {text: t('one_sided_friends.show.see_mutual_friends_html', num: @twitter_user.mutual_friendships.size), url: mutual_friend_path(@twitter_user)}
    ]
  end
end
