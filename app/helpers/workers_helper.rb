module WorkersHelper
  def enqueue_create_twitter_user_job_if_needed(uid, user_id:, screen_name:)
    return if from_crawler?
    return if !user_signed_in? && via_dm?
    return if uid.to_i == User::EGOTTER_UID

    return if TooManyRequestsQueue.new.exists?(current_user_id)

    requests = QueueingRequests.new(CreateTwitterUserWorker)
    return if requests.exists?(uid)
    requests.add(uid)

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

  def enqueue_create_follow_or_unfollow_job_if_needed(request, enqueue_location: nil)
    return if from_crawler?
    return if request.uid == User::EGOTTER_UID
    request.enqueue(enqueue_location: enqueue_location)
  end

  def enqueue_update_authorized
    return unless user_signed_in?
    UpdateAuthorizedWorker.perform_async(current_user.id, enqueued_at: Time.zone.now)
  end

  def enqueue_create_cache
    return unless user_signed_in?
    CreateCacheWorker.perform_async(user_id: current_user.id, enqueued_at: Time.zone.now)
  end

  def enqueue_audience_insight(uid)
    UpdateAudienceInsightWorker.perform_async(uid, enqueued_at: Time.zone.now)
  end
end
