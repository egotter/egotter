class InactiveFriendsController < ::Page::FriendsAndFollowers

  before_action(only: %i(show)) do
    if request.format.html?
      if valid_screen_name?(params[:screen_name])
        case params[:type]
          when 'inactive_friends' then redirect_to(inactive_friend_path(screen_name: params[:screen_name]), status: 301)
          when 'inactive_followers' then redirect_to(inactive_follower_path(screen_name: params[:screen_name]), status: 301)
          when 'inactive_mutual_friends' then redirect_to(inactive_mutual_friend_path(screen_name: params[:screen_name]), status: 301)
        end
      end
    else
      head :not_found
    end
  end

  before_action only: %i(new) do
    push_referer
    create_search_log
  end

  def new
  end

  def all
    super
    render template: 'friends/all' unless performed?
  end

  def show
    super
    @active_tab = 0
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
