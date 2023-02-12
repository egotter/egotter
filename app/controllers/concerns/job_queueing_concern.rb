require 'active_support/concern'

module JobQueueingConcern
  extend ActiveSupport::Concern

  def request_creating_twitter_user(uid)
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: #request_creating_twitter_user is stopped', uid: uid
      return
    end
    return unless user_signed_in?
    return if RateLimitExceededFlag.on?(current_user.id)
    return if TooManyFriendsSearchedFlag.on?(current_user.id)
    return if TwitterUserUpdatedFlag.on?(uid)
    return if TwitterUser.too_short_create_interval?(uid)
    return if CreateTwitterUserRequest.too_short_request_interval?(uid)

    TwitterUserUpdatedFlag.on(uid)

    request = CreateTwitterUserRequest.create(user_id: current_user.id, uid: uid, requested_by: controller_path)
    CreateTwitterUserWorker.perform_async(request.id, requested_by: controller_path)
  rescue => e
    Airbag.warn "#{__method__}: #{e.inspect} user_id=#{current_user.id} uid=#{uid} controller=#{controller_path}"
  end

  def request_assembling_twitter_user(twitter_user)
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: #request_assembling_twitter_user is stopped', twitter_user_id: twitter_user.id
      return
    end
    return unless user_signed_in?
    return if TwitterUserAssembledFlag.on?(twitter_user.uid)
    return if twitter_user.created_at > 30.seconds.ago
    return if twitter_user.assembled_at.present?

    TwitterUserAssembledFlag.on(twitter_user.uid)

    request = AssembleTwitterUserRequest.create(twitter_user: twitter_user, user_id: current_user.id, uid: twitter_user.uid, requested_by: controller_path)
    AssembleTwitterUserWorker.perform_async(request.id, requested_by: controller_path)
  rescue => e
    Airbag.warn "##{__method__}: #{e.inspect} twitter_user_id=#{twitter_user.id} controller=#{controller_path}"
  end

  def enqueue_update_authorized
    return if from_crawler?
    return unless user_signed_in?

    UpdateUserAttrsWorker.perform_async(current_user.id)
    update_twitter_db_user(current_user.uid)
  end

  def update_twitter_db_user(uid)
    if user_signed_in?
      CreateTwitterDBUserWorker.perform_async([uid], user_id: current_user.id, enqueued_by: current_via(__method__))
    end
  end

  def enqueue_update_egotter_friendship
    return if from_crawler?
    return unless user_signed_in?
    UpdateEgotterFriendshipWorker.perform_async(current_user.id)
  end
end
