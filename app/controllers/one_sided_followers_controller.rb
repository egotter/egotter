class OneSidedFollowersController < ::Page::Base
  include Concerns::FriendsConcern

  def all
    initialize_instance_variables
    @collection = @twitter_user.one_sided_followers.limit(300)
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
