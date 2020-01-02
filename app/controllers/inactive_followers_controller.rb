class InactiveFollowersController < ::Page::Base
  include Concerns::FriendsConcern

  def all
    initialize_instance_variables
    render template: 'friends/all' unless performed?
  end

  def show
    initialize_instance_variables
    @active_tab = 1
    render template: 'friends/show' unless performed?
  end

  private

  def related_counts
    {
      inactive_friends: @twitter_user.inactive_friendships.size,
      inactive_followers: @twitter_user.inactive_followerships.size,
      inactive_mutual_friends: @twitter_user.inactive_mutual_friendships.size
    }
  end

  def tabs
    [
      {text: t('inactive_friends.show.see_inactive_friends_html', num: @twitter_user.inactive_friendships.size), url: inactive_friend_path(@twitter_user)},
      {text: t('inactive_friends.show.see_inactive_followers_html', num: @twitter_user.inactive_followerships.size), url: inactive_follower_path(@twitter_user)},
      {text: t('inactive_friends.show.see_inactive_mutual_friends_html', num: @twitter_user.inactive_mutual_friendships.size), url: inactive_mutual_friend_path(@twitter_user)}
    ]
  end
end
