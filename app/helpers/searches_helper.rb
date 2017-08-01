module SearchesHelper
  def build_twitter_user(screen_name)
    redirect_path = root_path_for(controller: controller_name)

    if ForbiddenUser.exists?(screen_name: screen_name)
      twitter_user = TwitterUser.order(created_at: :desc).find_by(screen_name: screen_name)
      if twitter_user&.public_account?
        return twitter_user
      else
        return redirect_to redirect_path, alert: forbidden_message(screen_name)
      end
    end

    user = nil
    nf_screen_names = Util::NotFoundScreenNames.new(redis)
    nf_uids = Util::NotFoundUids.new(redis)

    begin
      user = client.user(screen_name)
    rescue Twitter::Error::NotFound => e
      nf_screen_names.add(screen_name)
    end unless nf_screen_names.exists?(screen_name)

    unless user
      begin
        user = client.user(screen_name.to_i)
      rescue Twitter::Error::NotFound => e
        nf_uids.add(screen_name)
      end if screen_name.match(Validations::UidValidator::REGEXP) && !nf_uids.exists?(screen_name)
    end

    if user
      TwitterUser.build_by_user(user)
    else
      redirect_to redirect_path, alert: not_found_message(screen_name)
    end

  rescue Twitter::Error::NotFound => e
    logger.warn "#{screen_name} is not found. #{current_user_id} #{request.device_type} #{request.browser} #{e.message}"
    redirect_to redirect_path, alert: not_found_message(screen_name)
  rescue Twitter::Error::Forbidden => e
    if e.message == 'User has been suspended.'
      CreateForbiddenUserWorker.perform_async(screen_name)
    else
      logger.warn "#{screen_name} is forbidden. #{current_user_id} #{request.device_type} #{request.browser} #{e.message}"
    end

    # TODO duplicate code
    twitter_user = TwitterUser.order(created_at: :desc).find_by(screen_name: screen_name)
    if twitter_user&.public_account?
      twitter_user
    else
      redirect_to redirect_path, alert: forbidden_message(screen_name)
    end
  rescue Twitter::Error::Unauthorized => e
    redirect_to redirect_path, alert: unauthorized_message(screen_name)
  rescue Twitter::Error::TooManyRequests => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{screen_name} #{current_user_id} #{request.device_type} #{request.browser}"
    logger.info e.backtrace.take(10).join("\n")
    redirect_to redirect_path, alert: alert_message(e)
  rescue => e
    # Twitter::Error execution expired
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{screen_name} #{current_user_id} #{request.device_type} #{request.browser}"
    logger.info e.backtrace.take(10).join("\n")
    Rollbar.error(e)
    redirect_to redirect_path, alert: alert_message(e)
  end

  def root_path_for(controller:)
    if %w(one_sided_friends unfriends relationships inactive_friends friends conversations clusters).include? controller
      send("#{controller}_top_path")
    else
      root_path
    end
  end

  def app_name_for(controller:)
    if %w(one_sided_friends unfriends relationships inactive_friends friends conversations clusters).include? controller
      send(:t, "#{controller}.new.title")
    else
      t('searches.common.egotter')
    end
  end

  def api_v1_summary_path_for(menu)
    menu = menu.to_s
    if menu == 'removing'
      menu = 'unfriends'
    elsif menu == 'removed'
      menu = 'unfollowers'
    end

    if Search::API_V1_NAMES.include? menu.to_sym
      send("api_v1_#{menu}_summary_path")
    else
      raise "#{__method__}: invalid menu #{menu}"
    end
  end

  def search_path_for(menu, screen_name)
    case menu.to_s
      when *%w(close_friends)
        close_friend_path(screen_name: screen_name)
      when *%w(new_friends new_followers favoriting close_friends usage_stats)
        send("#{menu}_search_path", screen_name: screen_name)
      when *%w(removing removed blocking_or_blocked)
        unfriend_path(screen_name: screen_name, type: menu)
      when *%w(one_sided_friends one_sided_followers mutual_friends)
        one_sided_friend_path(screen_name: screen_name, type: menu)
      when *%w(inactive_friends inactive_followers)
        inactive_friend_path(screen_name: screen_name, type: menu)
      when *%w(friends followers)
        friend_path(screen_name: screen_name, type: menu)
      when *%w(replying replied)
        conversation_path(screen_name: screen_name, type: menu)
      when *%w(clusters clusters_belong_to)
        cluster_path(screen_name: screen_name)
      else
        raise "#{__method__}: invalid menu #{menu}"
    end
  end

  def searches_path_for(controller:, screen_name: '', via: '')
    options = {screen_name: screen_name, via: via}.delete_if { |_, v| v.empty? }
    if %w(one_sided_friends unfriends relationships inactive_friends friends conversations clusters).include? controller
      send("#{controller}_path", options)
    else
      searches_path(options)
    end
  end

  def title_for(menu, screen_name)
    case menu.to_sym
      when :close_friends then t("close_friends.show.title")
      when :usage_stats then t("searches.usage_stats.name")
      when :clusters_belong_to then t("searches.clusters_belong_to.name")
      when :removing then t("searches.removing.name")
      when :removed then t("searches.removed.name")
      else t("searches.#{menu}.title", user: mention_name(screen_name))
    end
  end

  def description_for(menu, screen_name)
    if menu.to_sym == :close_friends
      t("close_friends.show.page_description", user: mention_name(screen_name))
    else
      t("searches.#{menu}.description", user: mention_name(screen_name))
    end
  end

  def users_for(tu, menu:)
    if %i(replied).include?(menu.to_sym)
      tu.send(menu, login_user: current_user)
    else
      if menu.to_sym == :close_friends
        uids = tu.close_friend_uids
        users = TwitterDB::User.where(uid: uids).index_by(&:uid)
        uids.map { |uid| users[uid] }.compact
      elsif menu.to_sym == :favoriting
        # TODO remove later
        result = tu.favorite_friends
        if result.any?
          result
        else
          uids = tu.calc_favorite_friend_uids
          users = TwitterDB::User.where(uid: uids).index_by(&:uid)
          uids.map { |uid| users[uid] }.compact
        end
      else
        tu.send(menu)
      end
    end
  end

  def uids_for(tu, menu:)
    uids_menu = "#{menu.singularize}_uids"
    if %i(replied_uids).include?(uids_menu.to_sym)
      tu.send(uids_menu, login_user: current_user)
    elsif uids_menu.to_sym == :favoriting_uids
      tu.favorite_friend_uids
    else
      tu.send(uids_menu)
    end
  end

  def chart_for(target, rest, label)
    total = target + rest
    [
      {name: t("charts.#{label}"), y: (target.to_f / total * 100)},
      {name: t('charts.others'), y: (rest.to_f / total * 100)}
    ]
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
