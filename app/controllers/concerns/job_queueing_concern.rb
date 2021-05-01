require 'active_support/concern'

module JobQueueingConcern
  extend ActiveSupport::Concern

  def enqueue_create_twitter_user_job_if_needed(uid, user_id:, force: false)
    return if from_crawler?
    return if !force && !user_signed_in?
    return if user_signed_in? && TooManyRequestsUsers.new.exists?(current_user.id)
    return if TwitterUser.too_short_create_interval?(uid)
    return if CreateTwitterUserRequest.too_short_request_interval?(uid)

    request = CreateTwitterUserRequest.create(
        requested_by: controller_path,
        session_id: egotter_visit_id,
        user_id: user_id,
        uid: uid,
        ahoy_visit_id: current_visit&.id)

    debug_info = {
        search_for_yourself: current_user&.uid == uid,
        controller: controller_path,
        action: action_name,
        user_id: user_id,
        uid: uid
    }

    if controller_name == 'searches' && user_signed_in?
      CreateHighPriorityTwitterUserWorker.perform_async(request.id, debug_info: debug_info)
    elsif user_signed_in?
      CreateSignedInTwitterUserWorker.perform_async(request.id, debug_info: debug_info)
    else
      CreateTwitterUserWorker.perform_async(request.id, debug_info: debug_info)
    end

  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.inspect} uid=#{uid} user_id=#{user_id} controller_name=#{controller_name}"
  end

  # TODO Update the data as priority if the user searches for yourself
  def enqueue_assemble_twitter_user(twitter_user)
    return if twitter_user.created_at > 10.seconds.ago
    return if twitter_user.assembled_at.present?
    return if from_crawler?
    return unless user_signed_in?

    request = AssembleTwitterUserRequest.create(twitter_user: twitter_user, requested_by: controller_path)

    debug_info = {
        user_id: current_user.id,
        search_for_yourself: current_user.uid == twitter_user.uid,
        twitter_user_id: twitter_user.id,
        uid: twitter_user.uid,
        friends_count: twitter_user.friends_count,
        followers_count: twitter_user.followers_count,
        created_at: twitter_user.created_at,
    }

    AssembleTwitterUserWorker.perform_async(request.id, requested_by: controller_name, debug_info: debug_info)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.inspect} twitter_user=#{twitter_user.inspect} controller_name=#{controller_name}"
  end

  def enqueue_update_authorized
    return if from_crawler?
    return unless user_signed_in?
    UpdateAuthorizedWorker.perform_async(current_user.id)
    CreateTwitterDBUserWorker.perform_async([current_user.uid], user_id: current_user.id, enqueued_by: current_via(__method__))
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
