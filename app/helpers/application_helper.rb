module ApplicationHelper
  def under_maintenance?
    ENV['MAINTENANCE'] == '1'
  end

  def root_page?
    controller_name == 'home' && action_name == 'new'
  end

  def top_page?
    (controller_name == 'home' && action_name == 'new') ||
        (controller_name == 'close_friends' && action_name == 'new') ||
        (controller_name == 'friends' && action_name == 'new') ||
        (controller_name == 'unfriends' && action_name == 'new') ||
        (controller_name == 'one_sided_friends' && action_name == 'new') ||
        (controller_name == 'inactive_friends' && action_name == 'new') ||
        (controller_name == 'clusters' && action_name == 'new') ||
        (controller_name == 'delete_tweets' && action_name == 'index') ||
        (controller_name == 'delete_favorites' && action_name == 'new') ||
        (controller_name == 'personality_insights' && action_name == 'new') ||
        (controller_name == 'tokimeki_unfollow' && action_name == 'new')
  end

  def waiting_page?
    controller_name == 'waiting'
  end

  def timeline_page?
    controller_name == 'timelines' && action_name == 'show'
  end

  def timeline_waiting_page?
    controller_name == 'timelines' && action_name == 'waiting'
  end

  def profile_page?
    controller_name == 'profiles' && action_name == 'show'
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
    delete_tweets = controller_name == 'delete_tweets' && action_name == 'index'
    settings = controller_name == 'settings' && action_name == 'index'
    trend_media = controller_name == 'trends' && action_name == 'media'
    slack_messages = controller_name == 'slack_messages'
    !top_page? && !waiting_page? && !delete_tweets && !settings && !trend_media && !slack_messages
  end

  def show_common_friends?(twitter_user)
    user_signed_in? && current_user.uid != twitter_user.uid && current_user.twitter_user
  end

  def show_redirection_modal?
    user_signed_in? && flash[:alert].blank? && !@bypassed_notice_message_set
  end

  def remove_related_page?
    %w(unfriends unfollowers mutual_unfriends).include?(controller_name)
  end

  def png_image
    @png_image ||= 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsQAAA7EAZUrDhsAAAANSURBVBhXYzh8+PB/AAffA0nNPuCLAAAAAElFTkSuQmCC'
  end
end
