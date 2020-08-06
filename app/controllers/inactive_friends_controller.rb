class InactiveFriendsController < ::Page::Base
  include Concerns::FriendsConcern

  before_action(only: %i(show)) do
    if request.format.html?
      if params[:type].present? && valid_screen_name?(params[:screen_name])
        case params[:type]
          when 'inactive_friends' then redirect_to(inactive_friend_path(screen_name: params[:screen_name]), status: 301)
          when 'inactive_followers' then redirect_to(inactive_follower_path(screen_name: params[:screen_name]), status: 301)
          when 'inactive_mutual_friends' then redirect_to(inactive_mutual_friend_path(screen_name: params[:screen_name]), status: 301)
        end
        logger.info "#{controller_name}##{action_name} redirect for backward compatibility type=#{params[:type]}"
      end
    else
      head :not_found
    end
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
end
