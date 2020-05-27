require 'active_support/concern'

module Concerns::JobQueueingConcern
  extend ActiveSupport::Concern

  included do
  end

  def enqueue_create_twitter_user_job_if_needed(uid, user_id:, requested_by: '')
    return if from_crawler?
    return if !user_signed_in? && via_dm?
    return if user_signed_in? && TooManyRequestsUsers.new.exists?(current_user.id)

    request = CreateTwitterUserRequest.create(
        requested_by: requested_by,
        session_id: egotter_visit_id,
        user_id: user_id,
        uid: uid,
        ahoy_visit_id: current_visit&.id)

    if controller_name == 'searches' && user_signed_in?
      CreateHighPriorityTwitterUserWorker.perform_async(request.id)
    elsif user_signed_in?
      CreateSignedInTwitterUserWorker.perform_async(request.id)
    else
      CreateTwitterUserWorker.perform_async(request.id)
    end
  end

  def enqueue_assemble_twitter_user(twitter_user)
    return if from_crawler?
    return unless user_signed_in?

    if twitter_user.assembled_at.blank?
      request = AssembleTwitterUserRequest.create(twitter_user: twitter_user)
      AssembleTwitterUserWorker.perform_async(request.id, requested_by: controller_name)
    end
  end

  def enqueue_update_authorized
    return if from_crawler?
    return unless user_signed_in?
    UpdateAuthorizedWorker.perform_async(current_user.id)
  end

  def enqueue_update_egotter_friendship
    return if from_crawler?
    return unless user_signed_in?
    UpdateEgotterFriendshipWorker.perform_async(current_user.id)
  end

  def enqueue_audience_insight(uid)
    return if from_crawler?
    UpdateAudienceInsightWorker.perform_async(uid, location: controller_name)
  end
end
