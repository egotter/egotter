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
        (controller_name == 'delete_favorites' && action_name == 'index')
  end

  RESULT_PAGES = %w(
    audience_insights
    close_friends
    clusters
    common_followers
    common_friends
    common_mutual_friends
    favorite_friends
    followers
    friends
    inactive_followers
    inactive_friends
    inactive_mutual_friends
    mutual_friends
    mutual_unfriends
    one_sided_followers
    one_sided_friends
    personality_insights
    replied
    replying_and_replied
    replying
    statuses
    unfollowers
    unfriends
    usage_stats
    word_clouds
  )

  def result_page?
    (controller_name == 'blockers' && action_name == 'index') ||
        (action_name == 'show' && RESULT_PAGES.include?(controller_name))
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

  def confirmation_page?
    %w(access_confirmations follow_confirmations interval_confirmations).include?(controller_name)
  end

  def delete_tweets_top_page?
    controller_name == 'delete_tweets' && action_name == 'index'
  end

  def delete_tweets_page?
    controller_name == 'delete_tweets'
  end

  def settings_page?
    controller_name == 'settings'
  end

  def show_header?
    !top_page?
  end

  def show_footer?
    !footer_disabled?
  end

  def footer_disabled?
    @footer_disabled
  end

  def footer_disabled=(flag)
    @footer_disabled = flag
  end

  def show_sidebar?
    !sidebar_disabled? && @twitter_user && !result_page? && !waiting_page?
  end

  def sidebar_disabled?
    @sidebar_disabled
  end

  def sidebar_disabled=(flag)
    @sidebar_disabled = flag
  end

  def wrap_in_container?
    settings = controller_name == 'settings' && action_name == 'index'
    pricing = controller_name == 'pricing'
    trend_media = controller_name == 'trends' && action_name == 'media'
    slack_messages = controller_name == 'slack_messages'
    !top_page? && !waiting_page? && !delete_tweets_top_page? && !settings && !pricing && !trend_media && !slack_messages
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
