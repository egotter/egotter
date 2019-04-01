module ApplicationHelper
  def under_maintenance?
    ENV['MAINTENANCE'] == '1'
  end

  def show_nav_buttons?
    !under_maintenance? && action_name != 'welcome'
  end

  def show_simple_header?
    controller_name == 'home' && action_name == 'new' && !user_signed_in?
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

  def top_page_paths
    [
      [one_sided_friends_top_path, t('one_sided_friends.new.simple_title')],
      [unfriends_top_path, t('unfriends.new.simple_title')],
      [inactive_friends_top_path, t('inactive_friends.new.simple_title')],
      [friends_top_path, t('friends.new.simple_title')],
      [clusters_top_path, t('clusters.new.simple_title')],
      [tokimeki_unfollow_top_path, t('tokimeki_unfollow.new.simple_title')],
      [delete_tweets_top_path, t('delete_tweets.new.simple_title')],
    ]
  end

  def egotter_share_text(shorten_url: false, via: nil)
    url = 'https://egotter.com'
    url += '?' + {via: via}.to_query if via
    url = Util::UrlShortener.shorten(url) if shorten_url
    t('tweet_text.top', kaomoji: Kaomoji.happy) + ' ' + url
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
