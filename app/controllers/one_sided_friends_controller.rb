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

  def new
  end

  def show
    initialize_instance_variables
    @active_tab = 0
    render template: 'result_pages/show' unless performed?
  end
end
