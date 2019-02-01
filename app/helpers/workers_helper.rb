module WorkersHelper
  def enqueue_create_twitter_user_job_if_needed(uid, user_id:, screen_name:)
    return if from_crawler?
    return if !user_signed_in? && via_dm?
    return if uid.to_i == User::EGOTTER_UID

    return if Util::TooManyRequestsRequests.exists?(current_user_id)

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
    UpdateSearchHistoriesWorker.perform_async(fingerprint, current_user_id, uid)
  end

  def enqueue_update_usage_stat_job_if_needed(uid)
    return if from_crawler?
    UpdateUsageStatWorker.perform_async(uid)
  end

  def enqueue_create_follow_job_if_needed(user_id)
    return if respond_to(:from_crawler?) && from_crawler?
    jobs = Concerns::User::FollowAndUnfollow::Util.collect_follow_or_unfollow_sidekiq_jobs('CreateFollowWorker', user_id)
    if jobs.empty?
      if Concerns::User::FollowAndUnfollow::Util.global_can_create_follow?
        CreateFollowWorker.perform_async(user_id)
      else
        CreateFollowWorker.perform_in(Concerns::User::FollowAndUnfollow::Util.limit_interval, user_id)
      end
    end
  end
  module_function :enqueue_create_follow_job_if_needed

  def enqueue_create_unfollow_job_if_needed(user_id)
    return if from_crawler?
    jobs = Concerns::User::FollowAndUnfollow::Util.collect_follow_or_unfollow_sidekiq_jobs('CreateUnfollowWorker', user_id)
    if jobs.empty?
      if Concerns::User::FollowAndUnfollow::Util.global_can_create_unfollow?
        CreateUnfollowWorker.perform_async(user_id)
      else
        CreateUnfollowWorker.perform_in(Concerns::User::FollowAndUnfollow::Util.limit_interval, user_id)
      end
    end
  end
end
