class InactiveFriendsController < ::Page::Base
  include Concerns::FriendsConcern

  before_action(only: %i(show)) do
    if request.format.html?
      if valid_screen_name?(params[:screen_name])
        case params[:type]
          when 'inactive_friends' then redirect_to(inactive_friend_path(screen_name: params[:screen_name]), status: 301)
          when 'inactive_followers' then redirect_to(inactive_follower_path(screen_name: params[:screen_name]), status: 301)
          when 'inactive_mutual_friends' then redirect_to(inactive_mutual_friend_path(screen_name: params[:screen_name]), status: 301)
        end
        logger.info "#{controller_name}##{action_name} redirect for backward compatibility"
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
    initialize_instance_variables
    render template: 'result_pages/all' unless performed?
  end

  def show
    initialize_instance_variables
    @active_tab = 0
    render template: 'result_pages/show' unless performed?
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
