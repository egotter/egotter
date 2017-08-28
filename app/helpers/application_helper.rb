module ApplicationHelper
  def under_maintenance?
    ENV['MAINTENANCE'] == '1'
  end

  def show_sidebar?
    %w(new waiting all).exclude?(action_name) && request.from_pc? && (@searched_tw_user || @twitter_user)
  end

  def show_see_at_once_button?
    %w(friends followers close_friends favorite_friends inactive_friends inactive_followers one_sided_friends one_sided_followers mutual_friends).include? controller_name
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
