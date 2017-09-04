module ApplicationHelper
  def under_maintenance?
    ENV['MAINTENANCE'] == '1'
  end

  def show_nav_buttons?
    !under_maintenance? && action_name != 'welcome'
  end

  def show_sidebar?
    %w(new waiting all).exclude?(action_name) && (from_crawler? || request.from_pc?) && @twitter_user && !@sidebar_disabled
  end

  def sidebar_disabled=(flag)
    @sidebar_disabled = flag
  end

  def show_common_friends?(twitter_user)
    user_signed_in? && current_user.uid != twitter_user.uid.to_i && current_user.twitter_user
  end

  def show_friends_stat?(twitter_user)
    %w(unfriends unfollowers blocking_or_blocked).exclude?(controller_name) && twitter_user.usage_stat
  end

  def stripe_enabled?
    user_signed_in? && current_user_uid == User::ADMIN_UID
  end

  def ad_disabled?
    current_user&.customer&.has_active_plan?
  end

  def top_page_paths
    [
      [one_sided_friends_top_path, t('one_sided_friends.new.plain_title')],
      [unfriends_top_path, t('unfriends.new.plain_title')],
      [inactive_friends_top_path, t('inactive_friends.new.plain_title')],
      [friends_top_path, t('friends.new.plain_title')],
      [clusters_top_path, t('clusters.new.plain_title')],
      [root_path, t('searches.common.egotter')]
    ]
  end

  def client
    @client ||= (user_signed_in? ? current_user.api_client : Bot.api_client)
  end

  def egotter_share_text(shorten_url: false, via: nil)
    url = 'https://egotter.com'
    url += '?' + {via: via}.to_query if via
    url = Util::UrlShortener.shorten(url) if shorten_url
    t('tweet_text.top', kaomoji: Kaomoji.happy) + ' ' + url
  end

  def kick_out_error_path(reason)
    welcome_path(via: "#{controller_name}/#{action_name}/#{reason}")
  end

  def png_image
    @png_image ||= 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsQAAA7EAZUrDhsAAAANSURBVBhXYzh8+PB/AAffA0nNPuCLAAAAAElFTkSuQmCC'
  end
end
