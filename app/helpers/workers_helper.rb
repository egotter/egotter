module WorkersHelper
  def add_create_twitter_user_worker_if_needed(uid, user_id:, screen_name:)
    return if request.from_crawler? || from_minor_crawler?(request.user_agent)

    searched_uids = Util::SearchedUids.new(redis)
    return if searched_uids.exists?(uid)
    searched_uids.add(uid)

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
      enqueued_at: Time.zone.now
    }

    if user_signed_in?
      CreateSignedInTwitterUserWorker.perform_async(values)
    else
      CreateTwitterUserWorker.perform_async(values)
    end
  end

  def add_create_relationship_worker_if_needed(uids, user_id:, screen_names:)
    return if request.from_crawler? || from_minor_crawler?(request.user_agent)

    searched_uids = Util::SearchedUids.new(redis)
    uids.each { |uid| searched_uids.add(uid) }
    referral = find_referral(pushed_referers)

    values = {
      session_id:   fingerprint,
      uids:         uids,
      screen_names: screen_names,
      user_id:      user_id,
      via:          params[:via] ? params[:via] : '',
      device_type:  request.device_type,
      os:           request.os,
      browser:      request.browser,
      user_agent:   truncated_user_agent,
      referer:      truncated_referer,
      referral:     referral,
      channel:      find_channel(referral),
    }
    CreateRelationshipWorker.perform_async(values)
  end
end
