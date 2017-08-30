module ApplicationHelper
  def under_maintenance?
    ENV['MAINTENANCE'] == '1'
  end

  def show_sidebar?
    %w(new waiting all).exclude?(action_name) && request.from_pc? && (@searched_tw_user || @twitter_user)
  end

  def show_see_at_once_button?
    true
  end

  def show_common_friends?(twitter_user)
    user_signed_in? && current_user.uid != twitter_user.uid.to_i && current_user.twitter_user
  end

  def top_page_paths
    [
      [one_sided_friends_top_path, t('one_sided_friends.new.plain_title')],
      [unfriends_top_path, t('unfriends.new.plain_title')],
      [relationships_top_path, t('relationships.new.plain_title')],
      [inactive_friends_top_path, t('inactive_friends.new.plain_title')],
      [friends_top_path, t('friends.new.plain_title')],
      [conversations_top_path, t('conversations.new.plain_title')],
      [clusters_top_path, t('clusters.new.plain_title')],
      [root_path, t('searches.common.egotter')]
    ]
  end

  def redis
    @redis ||= Redis.client
  end

  def client
    @client ||= (user_signed_in? ? current_user.api_client : Bot.api_client)
  end

  def admin_signed_in?
    user_signed_in? && current_user.admin?
  end

  def current_user_id
    @current_user_id ||= user_signed_in? ? current_user.id : -1
  end

  def current_user_uid
    @current_user_uid ||= user_signed_in? ? current_user.uid.to_i : -1
  end

  def egotter_share_text(shorten_url: false, via: nil)
    url = 'https://egotter.com'
    url += '?' + {via: via}.to_query if via
    url = Util::UrlShortener.shorten(url) if shorten_url
    t('tweet_text.top', kaomoji: Kaomoji.happy) + ' ' + url
  end

  def current_user_friend_uids
    if instance_variable_defined?(:@current_user_friend_uids)
      @current_user_friend_uids
    else
      @current_user_friend_uids = (current_user&.twitter_user&.friend_uids || [])
    end
  end

  def current_user_is_following?(uid)
    current_user_friend_uids.include? uid.to_i
  end

  def current_user_friend_screen_names
    if instance_variable_defined?(:@current_user_friend_screen_names)
      @current_user_friend_screen_names
    else
      @current_user_friend_screen_names = (current_user&.twitter_user&.friends&.pluck(:screen_name) || [])
    end
  end

  def from_minor_crawler?(user_agent)
    user_agent.to_s.match /Applebot|Jooblebot|SBooksNet|AdsBot-Google-Mobile|FlipboardProxy|HeartRails_Capture|Mail\.RU_Bot|360Spider/
  end

  def png_image
    @png_image ||= 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsQAAA7EAZUrDhsAAAANSURBVBhXYzh8+PB/AAffA0nNPuCLAAAAAElFTkSuQmCC'
  end
end
