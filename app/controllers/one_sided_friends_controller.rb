class OneSidedFriendsController < ::Page::Base
  include Concerns::FriendsConcern

  before_action(only: %i(show)) do
    if request.format.html?
      if params[:type].present? && valid_screen_name?(params[:screen_name])
        case params[:type]
          when 'one_sided_friends' then redirect_to(one_sided_friend_path(screen_name: params[:screen_name]), status: 301)
          when 'one_sided_followers' then redirect_to(one_sided_follower_path(screen_name: params[:screen_name]), status: 301)
          when 'mutual_friends' then redirect_to(mutual_friend_path(screen_name: params[:screen_name]), status: 301)
        end
        logger.info "#{controller_name}##{action_name} redirect for backward compatibility type=#{params[:type]}"
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
      one_sided_friends: @twitter_user.one_sided_friendships.size,
      one_sided_followers: @twitter_user.one_sided_followerships.size,
      mutual_friends: @twitter_user.mutual_friendships.size
    }
  end

  def tabs
    [
      {text: t('one_sided_friends.show.see_one_sided_friends_html', num: @twitter_user.one_sided_friendships.size), url: one_sided_friend_path(@twitter_user, via: current_via('tab'))},
      {text: t('one_sided_friends.show.see_one_sided_followers_html', num: @twitter_user.one_sided_followerships.size), url: one_sided_follower_path(@twitter_user, via: current_via('tab'))},
      {text: t('one_sided_friends.show.see_mutual_friends_html', num: @twitter_user.mutual_friendships.size), url: mutual_friend_path(@twitter_user, via: current_via('tab'))}
    ]
  end
end
