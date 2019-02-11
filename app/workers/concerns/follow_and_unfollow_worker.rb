require 'active_support/concern'

module Concerns::FollowAndUnfollowWorker
  extend ActiveSupport::Concern
  include Concerns::WorkerUtils

  class_methods do
  end

  included do
  end

  def do_perform(worker_class, request_class, user_id, options = {})
    request = nil
    request = request_class.unprocessed(user_id).order(created_at: :asc).first
    return unless request

    if request.ready?
      yield(request)
      request.finished!
      worker_class.perform_in(10.seconds, user_id, enqueue_location: 'FollowAndUnfollowWorker(finish)') if request_class.unprocessed(user_id).exists?
    else
      raise TooManyRequests
    end
  rescue => e
    if e.class == Twitter::Error::Unauthorized
      handle_unauthorized_exception(e, user_id: user_id)
    end

    if e.class == HaveAlreadyFollowed && request.uid == User::EGOTTER_UID
      logger.info "#{e.class} #{e.message} #{options} #{request.inspect}"
    else
      logger.warn "#{e.class} #{e.message} #{options} #{request.inspect}"
    end
    request.update(error_class: e.class, error_message: e.message.truncate(150))

    if e.class == HaveAlreadyFollowed && request.uid == User::EGOTTER_UID
      records = request_class.unprocessed(user_id).
          where('created_at < ?', request.created_at).
          where(uid: User::EGOTTER_UID)
      unless records.empty?
        records.update_all(error_class: e.class, error_message: e.message.truncate(150))
        logger.warn "Bulk update #{records.size} records. #{options} #{request.inspect}"
      end
    end

    interval = retry_immediately?(e) ? 10.seconds : Concerns::User::FollowAndUnfollow::Util.limit_interval

    if retry_immediately?(e)
      worker_class.perform_in(interval, user_id, enqueue_location: 'FollowAndUnfollowWorker(retry immediately)', request_id: request&.id, error_class: e.class)
    else
      worker_class.perform_in(interval, user_id, enqueue_location: 'FollowAndUnfollowWorker(retry)', request_id: request&.id, error_class: e.class)
    end
  end

  def retry_immediately?(ex)
    ex.message == 'Invalid or expired token.' ||
        ex.message.starts_with?("You've already requested to follow") ||
        [CanNotFollowYourself, CanNotUnfollowYourself, HaveAlreadyFollowed, HaveNotFollowed, HaveAlreadyRequestedToFollow].include?(ex.class)
  end

  class TooManyRequests < StandardError
    def initialize(message = "Follow or unfollow limit exceeded")
      super
    end
  end

  class CanNotFollowYourself < StandardError
    def initialize(message = "You can't follow yourself.")
      super
    end
  end

  class CanNotUnfollowYourself < StandardError
    def initialize(message = "You can't unfollow yourself.")
      super
    end
  end

  class HaveAlreadyFollowed < StandardError
    def initialize(message = "You've already followed the user.")
      super
    end
  end

  class HaveNotFollowed < StandardError
    def initialize(message = "You haven't followed the user.")
      super
    end
  end

  class HaveAlreadyRequestedToFollow < StandardError
    def initialize(message = "You've already requested to follow.")
      super
    end
  end


end
