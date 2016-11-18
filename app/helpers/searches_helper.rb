module SearchesHelper
  def build_twitter_user(screen_name)
    begin
      user = client.user(screen_name)
    rescue Twitter::Error::NotFound => e
      if screen_name.match(Validations::UidValidator::REGEXP)
        user = client.user(screen_name.to_i)
        if request.user_agent && request.user_agent.exclude?('Twitterbot')
          logger.warn "#{screen_name} is treated as uid. #{current_user_id} #{request.device_type} #{request.browser} #{request.referer}"
        end
      else
        raise e
      end
    end
    TwitterUser.build_by_user(user)
  rescue Twitter::Error::NotFound => e
    logger.warn "#{screen_name} is not found. #{current_user_id} #{request.device_type} #{request.browser}"
    redirect_to root_path, alert: alert_message(e)
  rescue Twitter::Error::TooManyRequests, Twitter::Error::NotFound, Twitter::Error::Unauthorized, Twitter::Error::Forbidden => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{screen_name} #{current_user_id} #{request.device_type}"
    logger.info "#{request.user_agent}"
    logger.info e.backtrace.take(10).join("\n")
    redirect_to root_path, alert: alert_message(e)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{screen_name} #{current_user_id} #{request.device_type}"
    logger.info e.backtrace.take(10).join("\n")
    Rollbar.error(e)
    redirect_to root_path, alert: alert_message(e)
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

    searched_uid_list = Util::SearchedUidList.new(redis)
    return if searched_uid_list.exists?(uid)

    referral = find_referral(pushed_referers)

    values = {
      session_id:  fingerprint,
      uid:         uid,
      screen_name: screen_name,
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
    }
    searched_uid_list.add(uid)
    CreateTwitterUserWorker.perform_async(values)
  end
end
