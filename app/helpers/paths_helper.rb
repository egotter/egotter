module PathsHelper
  def subroot_path
    via = current_via("root_path_for_#{controller_name}")
    case controller_name
    when 'one_sided_friends', 'unfriends', 'inactive_friends', 'friends', 'clusters', 'personality_insights' then send("#{controller_name}_top_path", via: via)
    when 'delete_tweets' then delete_tweets_path(via: via)
    when 'tokimeki_unfollow' then tokimeki_unfollow_cleanup_path(via: via)
    else root_path
    end
  end

  def api_path
    send("api_v1_#{controller_name}_list_path", via: current_via).html_safe
  end

  def api_profiles_count_path
    case controller_name
    when 'friends'
      api_v1_friend_insights_profiles_count_path(via: current_via)
    when 'followers'
      api_v1_follower_insights_profiles_count_path(via: current_via)
    else
      raise "#{__method__} Invalid controller_name value=#{controller_name}"
    end.html_safe
  end

  def sign_in_and_timeline_path(twitter_user, via:, follow: false)
    via = current_via(via)
    sign_in_path(follow: follow, via: via, redirect_path: timeline_path(twitter_user, via: via))
  end

  def scheduled_tweets_url(via: nil, utm_source: nil, utm_medium: nil, utm_campaign: nil)
    params = {
        via: via,
        utm_source: utm_source,
        utm_medium: utm_medium,
        utm_campaign: utm_campaign,
    }.select { |_, v| v }.to_param
    "https://scheduled-tweets.egotter.com?#{params}"
  end

  def transcription_ai_url
    'https://transcription-ai.com?via=egotter_footer&utm_source=egotter-footer&utm_medium=web&utm_campaign=egotter'
  end

  def android_app_url
    'https://play.google.com/store/apps/details?id=com.egotter&pcampaignid=pcampaignidMKT-Other-global-all-co-prtnr-py-PartBadge-Mar2515-1'
  end

  def current_via(suffix = nil)
    via = "#{controller_name}/#{action_name}"
    via += "/#{suffix}" if suffix
    via
  end
end
