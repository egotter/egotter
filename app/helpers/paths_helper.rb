module PathsHelper
  def root_path_for(controller:)
    via = build_via("root_path_for_#{controller}")
    case controller
    when 'one_sided_friends', 'unfriends', 'inactive_friends', 'friends', 'clusters' then send("#{controller}_top_path", via: via)
    when 'delete_tweets' then delete_tweets_path(via: via)
    when 'tokimeki_unfollow' then tokimeki_unfollow_cleanup_path(via: via)
    else root_path
    end
  end

  def search_path_for(menu, screen_name)
    via = build_via("search_path_for_#{menu}")
    case menu.to_s
      when 'omniauth_callbacks' then timeline_path(screen_name: screen_name, via: via)
      when *%w(home searches waiting notifications search_histories login misc orders tokimeki_unfollow delete_tweets application) then timeline_path(screen_name: screen_name, via: via)
      else send("#{menu.to_s.singularize}_path", screen_name: screen_name, via: via)
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{menu} #{screen_name}"

    # TODO This method is undefined in view context
    notify_airbrake(e) rescue nil

    timeline_path(screen_name: screen_name, via: via)
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

  def build_via(suffix = nil)
    via = "#{controller_name}/#{action_name}"
    via += "/#{suffix}" if suffix
    via
  end
end
