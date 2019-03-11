class UnfriendsController < ::Page::UnfriendsAndUnfollowers
  include TweetTextHelper

  before_action(only: %i(show)) do
    if request.format.html?
      if valid_screen_name?(params[:screen_name])
        case params[:type]
          when 'removing' then redirect_to(unfriend_path(screen_name: params[:screen_name]), status: 301)
          when 'removed' then redirect_to(unfollower_path(screen_name: params[:screen_name]), status: 301)
          when 'blocking_or_blocked' then redirect_to(blocking_or_blocked_path(screen_name: params[:screen_name]), status: 301)
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
    render template: 'unfriends/show' unless performed?
  end
end
