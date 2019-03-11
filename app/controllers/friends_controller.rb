class FriendsController < ::Page::FriendsAndFollowers

  before_action(only: %i(show)) do
    if request.format.html?
      if valid_screen_name?(params[:screen_name])
        case params[:type]
          when 'friends' then redirect_to(friend_path(screen_name: params[:screen_name]), status: 301)
          when 'followers' then redirect_to(follower_path(screen_name: params[:screen_name]), status: 301)
          when 'statuses' then redirect_to(status_path(screen_name: params[:screen_name]), status: 301)
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
  end

  def show
    super
    @active_tab = 0
  end

  private

  def related_counts
    {
      friends: @twitter_user.friend_uids.size,
      one_sided_friends: @twitter_user.one_sided_friendships.size,
      one_sided_friends_rate: (@twitter_user.one_sided_friends_rate * 100).round(1)
    }
  end

  def tabs
    [
      {text: t('friends.show.see_friends_html', num: @twitter_user.friend_uids.size), url: friend_path(@twitter_user)},
      {text: t('friends.show.see_followers_html', num: @twitter_user.follower_uids.size), url: follower_path(@twitter_user)}
    ]
  end
end
