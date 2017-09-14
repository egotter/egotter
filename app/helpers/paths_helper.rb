module PathsHelper
  def root_path_for(controller:)
    if %w(one_sided_friends unfriends inactive_friends friends clusters).include? controller
      send("#{controller}_top_path")
    else
      root_path
    end
  end

  def search_path_for(menu, screen_name)
    case menu.to_s
      when *%w(searches notifications search_histories login misc application) then timeline_path(screen_name: screen_name)
      else send("#{menu.to_s.singularize}_path", screen_name: screen_name)
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    timeline_path(screen_name: screen_name)
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
end
