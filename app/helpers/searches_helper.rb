module SearchesHelper
  def build_twitter_user(screen_name)
    user = client.user(screen_name)
    twitter_user = TwitterUser.build_by_user(user)

    DeleteNotFoundUserWorker.perform_async(screen_name)
    DeleteForbiddenUserWorker.perform_async(screen_name)

    twitter_user
  rescue => e
    if e.message == 'User not found.'
      CreateNotFoundUserWorker.perform_async(screen_name)
    elsif e.message == 'User has been suspended.'
      CreateForbiddenUserWorker.perform_async(screen_name)
    end

    if can_see_forbidden_or_not_found?(screen_name: screen_name)
      TwitterUser.order(created_at: :desc).find_by(screen_name: screen_name)
    else
      twitter_exception_handler(e, screen_name)
    end
  end

  def root_path_for(controller:)
    if %w(one_sided_friends unfriends inactive_friends friends clusters).include? controller
      send("#{controller}_top_path")
    else
      root_path
    end
  end

  def app_name_for(controller:)
    if %w(one_sided_friends unfriends relationships inactive_friends friends conversations clusters).include? controller
      send(:t, "#{controller}.new.title_html")
    else
      t('searches.common.egotter')
    end
  end

  def search_path_for(menu, screen_name)
    case menu.to_s
      when *%w(searches notifications login) then timeline_path(screen_name: screen_name)
      else send("#{menu.to_s.singularize}_path", screen_name: screen_name)
    end
  end

  def searches_path_for(screen_name:, via:)
    url = search_path_for(controller_name, screen_name)
    searches_path(screen_name: screen_name, via: via, redirect_path: url)
  end

  def fetch_twitter_user_from_cache(uid)
    attrs = Util::ValidTwitterUserSet.new(redis).get(uid)
    return nil if attrs.nil?

    TwitterUser.new(
      uid: attrs['uid'],
      screen_name: attrs['screen_name'],
      user_info: attrs['user_info'],
    )
  end

  def save_twitter_user_to_cache(uid, screen_name:, user_info:)
    Util::ValidTwitterUserSet.new(redis).set(
      uid,
      {uid: uid, screen_name: screen_name, user_info: user_info}
    )
  end

  def reject_crawler
    if request.from_crawler?
      render text: t('before_sign_in.reject_crawler')
    end
  end
end
