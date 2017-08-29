module WorkersHelper
  def enqueue_create_twitter_user_job_if_needed(uid, user_id:, screen_name:)
    return if request.from_crawler? || from_minor_crawler?(request.user_agent)
    return if uid.to_i == User::EGOTTER_UID

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

    track = Track.new(values.slice(:session_id, :user_id, :uid, :screen_name, :auto, :via, :device_type, :os, :browser, :user_agent, :referer, :referral, :channel, :medium))
    track.update(controller: controller_name, action: action_name)

    worker_class = user_signed_in? ? CreateSignedInTwitterUserWorker : CreateTwitterUserWorker
    worker_class.perform_async(values.merge(track_id: track.id))
  end

  def enqueue_create_relationship_job_if_needed(uids, user_id:, screen_names:)
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

  def enqueue_update_search_histories_job_if_needed(uid)
    return if request.from_crawler? || from_minor_crawler?(request.user_agent)
    UpdateSearchHistoriesWorker.perform_in(1.minutes, fingerprint, current_user_id, uid)
  end

  def enqueue_update_usage_stat_job_if_needed(uid)
    return if request.from_crawler? || from_minor_crawler?(request.user_agent)
    UpdateUsageStatWorker.perform_async(uid)
  end
end
