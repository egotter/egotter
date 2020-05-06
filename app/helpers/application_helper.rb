module ApplicationHelper
  def under_maintenance?
    ENV['MAINTENANCE'] == '1'
  end

  def show_header?
    top = controller_name == 'home' && action_name == 'new'
    friends = controller_name == 'friends' && action_name == 'new'
    unfriends = controller_name == 'unfriends' && action_name == 'new'
    one_sided_friends = controller_name == 'one_sided_friends' && action_name == 'new'
    inactive_friends = controller_name == 'inactive_friends' && action_name == 'new'
    clusters = controller_name == 'clusters' && action_name == 'new'
    tokimeki = controller_name == 'tokimeki_unfollow' && action_name == 'new'
    !top && !friends && !unfriends && !one_sided_friends && !inactive_friends && !clusters && !tokimeki
  end

  def show_sidebar?
    !sidebar_disabled && @twitter_user && action_name != 'all' &&
        controller_name != 'waiting' && controller_name != 'tokimeki_unfollow'
  end

  def sidebar_disabled
    @sidebar_disabled
  end

  def sidebar_disabled=(flag)
    @sidebar_disabled = flag
  end

  def wrap_in_container?
    top = controller_name == 'home' && action_name == 'new'
    start = controller_name == 'home' && action_name == 'start'
    waiting = controller_name == 'waiting' && action_name == 'new'
    one_sided_friends = controller_name == 'one_sided_friends' && action_name == 'new'
    unfriends = controller_name == 'unfriends' && action_name == 'new'
    inactive_friends = controller_name == 'inactive_friends' && action_name == 'new'
    friends = controller_name == 'friends' && action_name == 'new'
    clusters = controller_name == 'clusters' && action_name == 'new'
    delete_tweets = controller_name == 'delete_tweets' && action_name == 'new'
    settings = controller_name == 'settings' && action_name == 'index'
    tokimeki = controller_name == 'tokimeki_unfollow' && action_name == 'new'
    !@has_error && !top && !start && !waiting && !unfriends && !one_sided_friends && !inactive_friends && !friends && !clusters && !delete_tweets && !settings && !tokimeki
  end

  def show_common_friends?(twitter_user)
    user_signed_in? && current_user.uid != twitter_user.uid.to_i && current_user.twitter_user
  end

  def show_friends_stat?(twitter_user)
    %w(unfriends unfollowers blocking_or_blocked).exclude?(controller_name) && twitter_user.usage_stat
  end

  def show_redirection_modal?
    user_signed_in? && !@has_error && flash[:alert].blank?
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
