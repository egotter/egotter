module ApplicationHelper
  def under_maintenance?
    ENV['MAINTENANCE'] == '1'
  end

  def show_sidebar?
    %w(new waiting).exclude?(action_name) && request.device_type == :pc && (@searched_tw_user || @twitter_user)
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

  def search_oneself?(uid)
    user_signed_in? && current_user.uid.to_i == uid.to_i
  end

  def search_others?(uid)
    user_signed_in? && current_user.uid.to_i != uid.to_i
  end

  def current_user_id
    @current_user_id ||= user_signed_in? ? current_user.id : -1
  end

  def egotter_share_text
    @egotter_share_text ||= t('tweet_text.top', kaomoji: Kaomoji.happy)
  end

  def screen_names_for_search
    @screen_names_for_search ||=
      begin
        json = redis.fetch("screen_names_for_search:#{current_user_id}", ttl: 1.day) do
          if user_signed_in? && (tu = current_user.twitter_user)
            tu.friends.pluck(:screen_name)
          else
            []
          end.to_json
        end
        JSON.load(json)
      end
  end

  def png_image
    @png_image ||= 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsQAAA7EAZUrDhsAAAANSURBVBhXYzh8+PB/AAffA0nNPuCLAAAAAElFTkSuQmCC'
  end
end
