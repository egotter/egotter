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

  def search_link(screen_name, via, options = {}, &block)
    if from_crawler?
      url = timeline_path(screen_name: screen_name, via: via)
    else
      url = searches_path(screen_name: screen_name, via: via)
      options.merge!(method: :post)
    end

    url = CGI::unescape(url) if options.delete(:unescape)

    block_given? ? link_to(url, options, &block) : link_to(mention_name(screen_name), url, options)
  end

  def current_via(suffix = nil)
    via = "#{controller_name}/#{action_name}"
    via += "/#{suffix}" if suffix
    via
  end
end
