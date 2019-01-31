require 'active_support/concern'

module Concerns::FollowAndUnfollowWorker
  extend ActiveSupport::Concern
  include Concerns::WorkerUtils

  class_methods do
  end

  included do
  end

  def do_perform(worker_class, request_class, user_id)
    request = request_class.unprocessed(user_id).order(created_at: :asc).first
    return unless request

    if request.ready?
      yield(request)
      request.finished!
      worker_class.perform_async(user_id) if request_class.unprocessed(user_id).exists?
    else
      logger.warn "Follow or unfollow limit exceeded #{request.inspect}"
      worker_class.perform_in(Concerns::User::FollowAndUnfollow::Util.limit_interval.since, user_id)
    end
  rescue => e
    if e.class == Twitter::Error::Unauthorized
      handle_unauthorized_exception(e, user_id: user_id)
    elsif e.class == Twitter::Error::Forbidden
      handle_forbidden_exception(e, user_id: user_id)
    end

    logger.warn "#{e.class} #{e.message} #{user_id} #{request.inspect}"
    request.update(error_class: e.class, error_message: e.message.truncate(150))
    worker_class.perform_in(Concerns::User::FollowAndUnfollow::Util.limit_interval.since, user_id)
  end
end
