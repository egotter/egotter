module SearchesHelper
  def set_twitter_user
    unless TwitterUser.new(uid: params[:id]).valid_uid?
      logger.info "#{self.class}##{__method__}: The uid is invalid. #{params[:id]} #{current_user_id} #{action_name} #{request.device_type}."
      if request.xhr?
        return render nothing: true, status: 400
      else
        return redirect_to '/', alert: t('before_sign_in.that_page_doesnt_exist')
      end
    end

    uid = params[:id].to_i
    user_id = current_user_id

    if TwitterUser.exists?(uid: uid, user_id: user_id)
      tu = TwitterUser.latest(uid, user_id)
      tu.assign_attributes(client: client, egotter_context: 'search')
      @searched_tw_user = tu
    else
      logger.info "#{self.class}##{__method__}: The TwitterUser doesn't exist. #{uid} #{user_id} #{action_name} #{request.device_type}."
      if request.xhr?
        return render nothing: true, status: 400
      else
        redirect_to '/', alert: t('before_sign_in.that_page_doesnt_exist')
      end
    end
  end

  def fetch_twitter_user_from_cache(uid, user_id)
    attrs = Util::ValidTwitterUserSet.new(redis).get(uid, user_id)
    return nil if attrs.nil?

    TwitterUser.new(
      uid: attrs['uid'],
      screen_name: attrs['screen_name'],
      user_id: attrs['user_id'],
      user_info: attrs['user_info'],
      egotter_context: 'search'
    )
  end

  def save_twitter_user_to_cache(uid, user_id, screen_name:, user_info:)
    Util::ValidTwitterUserSet.new(redis).set(
      uid,
      user_id,
      {uid: uid, user_id: user_id, screen_name: screen_name, user_info: user_info}
    )
  end

  def reject_crawler
    if request.device_type == :crawler
      logger.warn "#{self.class}##{__method__}: The crawler is rejected from #{action_name}."
      render text: t('before_sign_in.that_page_doesnt_exist')
    end
  end

  def add_background_search_worker_if_needed(uid, user_id, screen_name:)
    searched_uid_list = Util::SearchedUidList.new(redis)
    unless searched_uid_list.exists?(uid, user_id)
      values = {
        session_id: fingerprint,
        uid: uid,
        screen_name: screen_name,
        user_id: user_id,
        auto: %w(show).include?(action_name),
        device_type: request.device_type,
        os: request.os,
        browser: request.browser,
        user_agent: truncated_user_agent,
        referer: truncated_referer,
        channel: find_channel,
        url: search_url(screen_name: screen_name, id: uid)
      }
      searched_uid_list.add(uid, user_id)
      CreateTwitterUserWorker.perform_async(values)
    end
  end
end