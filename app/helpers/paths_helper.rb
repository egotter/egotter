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
    send("api_v1_#{controller_name}_list_path", via: current_via)
  end

  def current_via(suffix = nil)
    via = "#{controller_name}/#{action_name}"
    via += "/#{suffix}" if suffix
    via
  end
end
