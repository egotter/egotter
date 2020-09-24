module ApplicationHelper
  def under_maintenance?
    ENV['MAINTENANCE'] == '1'
  end

  def top_page?
    (controller_name == 'home' && action_name == 'new') ||
        (controller_name == 'friends' && action_name == 'new') ||
        (controller_name == 'unfriends' && action_name == 'new') ||
        (controller_name == 'one_sided_friends' && action_name == 'new') ||
        (controller_name == 'inactive_friends' && action_name == 'new') ||
        (controller_name == 'clusters' && action_name == 'new') ||
        (controller_name == 'delete_tweets' && action_name == 'new') ||
        (controller_name == 'personality_insights' && action_name == 'new') ||
        (controller_name == 'tokimeki_unfollow' && action_name == 'new')
  end

  def waiting_page?
    controller_name == 'waiting'
  end

  def start_page?
    controller_name == 'home' && action_name == 'start'
  end

  def show_header?
    !top_page?
  end

  def show_sidebar?
    !sidebar_disabled? && @twitter_user && !waiting_page? && controller_name != 'tokimeki_unfollow'
  end

  def sidebar_disabled?
    @sidebar_disabled
  end

  def sidebar_disabled=(flag)
    @sidebar_disabled = flag
  end

  def wrap_in_container?
    settings = controller_name == 'settings' && action_name == 'index'
    !@has_error && !top_page? && !waiting_page? && !settings
  end

  def show_common_friends?(twitter_user)
    user_signed_in? && current_user.uid != twitter_user.uid && current_user.twitter_user
  end

  def show_redirection_modal?
    user_signed_in? && !@has_error && flash[:alert].blank?
  end

  def remove_related_page?
    %w(unfriends unfollowers blocking_or_blocked).include?(controller_name)
  end

  def kick_out_error_path(reason, redirect_path: nil)
    if redirect_path
      sign_in_path(via: "#{controller_name}/#{action_name}/#{reason}", redirect_path: redirect_path)
    else
      sign_in_path(via: "#{controller_name}/#{action_name}/#{reason}")
    end
  end

  ANCHOR_REGEXP = /(#[a-zA-Z0-9_-]+)/

  def append_query_params(path, params)
    path += path.include?('?') ? '&' : '?'
    path + params.to_query

    if path.match?(ANCHOR_REGEXP)
      anchor = path.match(ANCHOR_REGEXP)[0]
      path.remove!(ANCHOR_REGEXP)
      path = path + anchor
    end

    path
  end

  def png_image
    @png_image ||= 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsQAAA7EAZUrDhsAAAANSURBVBhXYzh8+PB/AAffA0nNPuCLAAAAAElFTkSuQmCC'
  end
end
