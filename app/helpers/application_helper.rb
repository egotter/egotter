module ApplicationHelper
  def under_maintenance?
    ENV['MAINTENANCE'] == '1'
  end

  def show_simple_header?
    (controller_name == 'home' && action_name == 'new' && !user_signed_in?) ||
        (controller_name == 'unfriends' && action_name == 'new' && !user_signed_in?)
  end

  def show_sidebar?
    %w(home waiting tokimeki_unfollow).exclude?(controller_name) &&
        %w(new all).exclude?(action_name) &&
        (from_crawler? || request.from_pc?) &&
        @twitter_user && !@sidebar_disabled
  end

  def sidebar_disabled=(flag)
    @sidebar_disabled = flag
  end

  def wrap_in_container?
    !(controller_name == 'home' && action_name == 'new') &&
        !(controller_name == 'settings' && action_name == 'index')
  end

  def show_common_friends?(twitter_user)
    user_signed_in? && current_user.uid != twitter_user.uid.to_i && current_user.twitter_user
  end

  def show_friends_stat?(twitter_user)
    %w(unfriends unfollowers blocking_or_blocked).exclude?(controller_name) && twitter_user.usage_stat
  end

  def show_sign_in_button_at_bottom?
    !user_signed_in? && show_announcement_section?
  end

  def show_functions_section?
    show_announcement_section?
  end

  def show_announcement_section?
    tokimeki = controller_name == 'tokimeki_unfollow' && action_name == 'cleanup'
    start = controller_name == 'home' && action_name == 'start'
    directory = controller_path.match?(/^directory/)
    settings = controller_name == 'settings'
    pricing = controller_name == 'pricing'
    login = controller_name == 'login'
    misc = controller_name == 'misc'

    !tokimeki && !start && !directory && !settings && !pricing && !login && !misc
  end

  def kick_out_error_path(reason, redirect_path: nil)
    if redirect_path
      sign_in_path(via: "#{controller_name}/#{action_name}/#{reason}", redirect_path: redirect_path)
    else
      sign_in_path(via: "#{controller_name}/#{action_name}/#{reason}")
    end
  end

  def append_query_params(path, params)
    path += path.include?('?') ? '&' : '?'
    path + params.to_query
  end

  def png_image
    @png_image ||= 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsQAAA7EAZUrDhsAAAANSURBVBhXYzh8+PB/AAffA0nNPuCLAAAAAElFTkSuQmCC'
  end
end
