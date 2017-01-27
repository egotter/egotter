module SearchesHelper
  def build_twitter_user(screen_name)
    user = nil
    nf_screen_names = Util::NotFoundScreenNames.new(redis)
    nf_uids = Util::NotFoundUids.new(redis)
    redirect_path = root_path_for(controller: controller_name)

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
      logger.info "#{screen_name} is not found. #{current_user_id} #{request.device_type} #{request.browser} #{request.user_agent}"
      redirect_to redirect_path, alert: not_found_message(screen_name)
    end

  rescue Twitter::Error::NotFound => e
    logger.warn "#{screen_name} is not found. #{current_user_id} #{request.device_type} #{request.browser} #{request.user_agent}"
    logger.info e.backtrace.take(10).join("\n")
    redirect_to redirect_path, alert: not_found_message(screen_name)
  rescue Twitter::Error::TooManyRequests, Twitter::Error::Unauthorized, Twitter::Error::Forbidden => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{screen_name} #{current_user_id} #{request.device_type} #{request.user_agent}"
    logger.info e.backtrace.take(10).join("\n")
    redirect_to redirect_path, alert: alert_message(e)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{screen_name} #{current_user_id} #{request.device_type} #{request.user_agent}"
    logger.info e.backtrace.take(10).join("\n")
    Rollbar.error(e)
    redirect_to redirect_path, alert: alert_message(e)
  end

  def root_path_for(controller:)
    case controller
      when 'one_sided_friends' then one_sided_friends_top_path
      when 'unfriends' then unfriends_top_path
      else root_path
    end
  end

  def app_name_for(controller:)
    case controller
      when %r{one_sided_friends|one_sided_followers}
        t('one_sided_friends.new.title')
      when %r{unfriends}
        t('unfriends.new.title')
      else
        t('searches.common.egotter')
    end
  end

  def search_path_for(controller:, screen_name:, via: '')
    case controller
      when 'one_sided_friends' then one_sided_friends_path(screen_name: screen_name, via: via)
      when 'unfriends' then unfriends_path(screen_name: screen_name, via: via)
      else searches_path(screen_name: screen_name, via: via)
    end
  end

  def title_for(tu, menu:)
    if %i(common_friends common_followers).include?(menu)
      t("searches.#{menu}.title", user: tu.mention_name, login: I18n.t('dictionary.you'))
    else
      t("searches.#{menu}.title", user: tu.mention_name)
    end
  end

  def description_for(tu, menu:)
    t("searches.#{menu}.description", user: tu.mention_name)
  end

  def users_for(tu, menu:)
    if %i(close_friends).include?(menu)
      tu.send(menu, login_user: current_user)
    else
      tu.send(menu)
    end
  end

  def graph_for(tu, menu:, users: nil)
    if %i(replying replied favoriting close_friends).include?(menu)
      tu.send("#{menu}_graph", users)
    else
      tu.send("#{menu}_graph")
    end
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
    if request.device_type == :crawler
      logger.warn "#{self.class}##{__method__}: The crawler is rejected from #{action_name}."
      render text: t('before_sign_in.reject_crawler')
    end
  end

  def add_create_twitter_user_worker_if_needed(uid, user_id:, screen_name:)
    return if request.device_type == :crawler

    searched_uids = Util::SearchedUids.new(redis)
    return if searched_uids.exists?(uid)

    referral = find_referral(pushed_referers)

    values = {
      session_id:  fingerprint,
      uid:         uid,
      screen_name: screen_name,
      action:      action_name,
      user_id:     user_id,
      auto:        %w(show).include?(action_name),
      via:         params[:via] ? params[:via] : '',
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      user_agent:  truncated_user_agent,
      referer:     truncated_referer,
      referral:    referral,
      channel:     find_channel(referral),
      medium:      params[:medium] ? params[:medium] : '',
    }
    searched_uids.add(uid)
    jid = CreateTwitterUserWorker.perform_async(values)
    logger.info "#{self.class}##{__method__}: #{jid}"
    jid
  end
end
