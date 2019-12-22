require 'active_support/concern'

module Concerns::JobQueueingConcern
  extend ActiveSupport::Concern

  included do
  end

  def enqueue_create_twitter_user_job_if_needed(uid, user_id:, requested_by: '')
    return if from_crawler?
    return if !user_signed_in? && via_dm?
    return if user_signed_in? && TooManyRequestsUsers.new.exists?(current_user.id)

    # This value is used in #searched_uid? to redirect to an error page when the uid is not searched.
    queue = EnqueuedSearchRequest.new
    if queue.exists?(uid)
      logger.debug { "#{controller_name}##{action_name} Queueing of CreateSignedInTwitterUserWorker is skipped #{user_id} #{uid}" }
      return
    end
    queue.add(uid)

    request = CreateTwitterUserRequest.create(
        requested_by: requested_by,
        session_id: egotter_visit_id,
        user_id: user_id,
        uid: uid,
        ahoy_visit_id: current_visit&.id)

    if user_signed_in?
      CreateSignedInTwitterUserWorker.perform_async(request.id, enqueued_at: Time.zone.now)
    else
      CreateTwitterUserWorker.perform_async(request.id, enqueued_at: Time.zone.now)
    end
  end

  def enqueue_update_authorized
    return if from_crawler?
    return unless user_signed_in?
    UpdateAuthorizedWorker.perform_async(current_user.id, enqueued_at: Time.zone.now)
  end

  def enqueue_update_egotter_friendship
    return if from_crawler?
    return unless user_signed_in?
    UpdateEgotterFriendshipWorker.perform_async(current_user.id, enqueued_at: Time.zone.now)
  end

  def enqueue_audience_insight(uid)
    return if from_crawler?
    UpdateAudienceInsightWorker.perform_async(uid, enqueued_at: Time.zone.now, location: controller_name)
  end
end
