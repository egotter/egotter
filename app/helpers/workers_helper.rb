module WorkersHelper
  def enqueue_create_twitter_user_job_if_needed(uid, user_id:, screen_name:)
    return if from_crawler?
    return if uid.to_i == User::EGOTTER_UID

    return if Util::SearchRequests.exists?(uid)
    Util::SearchRequests.add(uid)

    referral = find_referral(pushed_referers)

    values = {
      session_id:  fingerprint,
      user_id:     user_id,
      uid:         uid,
      screen_name: screen_name,
      controller:  controller_name,
      action:      action_name,
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

    track = Track.create!(values.except(:enqueued_at))

    worker_class = user_signed_in? ? CreateSignedInTwitterUserWorker : CreateTwitterUserWorker
    worker_class.perform_async(values.merge(track_id: track.id))
  end

  def enqueue_update_search_histories_job_if_needed(uid)
    return if from_crawler?
    UpdateSearchHistoriesWorker.perform_in(1.minutes, fingerprint, current_user_id, uid)
  end

  def enqueue_update_usage_stat_job_if_needed(uid)
    return if from_crawler?
    UpdateUsageStatWorker.perform_async(uid)
  end
end
