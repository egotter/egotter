module SearchesHelper
  def build_twitter_user(screen_name)
    TwitterUser.build_by_user(client.user(screen_name))
  rescue Twitter::Error::TooManyRequests => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{screen_name}"
    redirect_to root_path, alert: t('before_sign_in.too_many_requests', sign_in_link: view_context.link_to(t('dictionary.sign_in'), welcome_path))
  rescue Twitter::Error::NotFound => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{screen_name} #{current_user_id} #{request.device_type}"
    redirect_to root_path, alert: t('before_sign_in.not_found')
  rescue Twitter::Error::Forbidden => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{screen_name} #{current_user_id} #{request.device_type}"
    redirect_to root_path, alert: t('before_sign_in.forbidden')
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{screen_name} #{current_user_id} #{request.device_type}"
    logger.info e.backtrace.slice(0, 10).join("\n")
    redirect_to root_path, alert: t('before_sign_in.something_is_wrong', sign_in_link: view_context.link_to(t('dictionary.sign_in'), welcome_path))
  end

  def fetch_twitter_user_with_client(uid)
    tu = TwitterUser.latest(uid)
    tu.assign_attributes(client: client)
    tu
  end

  def title_for(tu, menu: nil)
    if %i(common_friends common_followers).include?(menu)
      t("searches.#{menu}.title", user: tu.mention_name, login: I18n.t('dictionary.you'))
    else
      t("searches.#{menu}.title", user: tu.mention_name)
    end
  end

  def fetch_twitter_user_from_cache(uid)
    attrs = Util::ValidTwitterUserSet.new(redis).get(uid)
    return nil if attrs.nil?

    TwitterUser.new(
      uid: attrs['uid'],
      screen_name: attrs['screen_name'],
      user_info_gzip: Base64.decode64(attrs['user_info_gzip']),
    )
  end

  def save_twitter_user_to_cache(uid, screen_name:, user_info_gzip:)
    Util::ValidTwitterUserSet.new(redis).set(
      uid,
      {uid: uid, screen_name: screen_name, user_info_gzip: Base64.encode64(user_info_gzip)}
    )
  end

  def reject_crawler
    if request.device_type == :crawler
      logger.warn "#{self.class}##{__method__}: The crawler is rejected from #{action_name}."
      render text: t('before_sign_in.reject_crawler')
    end
  end

  def add_background_search_worker_if_needed(uid, user_id:, screen_name:)
    searched_uid_list = Util::SearchedUidList.new(redis)
    unless searched_uid_list.exists?(uid)
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
        channel:     find_channel,
        url:         search_url(screen_name: screen_name, id: uid)
      }
      searched_uid_list.add(uid)
      CreateTwitterUserWorker.perform_async(values)
    end
  end
end