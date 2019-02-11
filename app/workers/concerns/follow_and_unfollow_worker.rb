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
    request = request_class.next_request(user_id)
    return unless request

    if request_class.global_can_perform?
      request.perform!
      request_class.next_request(user_id)&.enqueue(enqueue_location: 'Finish')
    else
      raise TooManyRequests
    end
  rescue TooManyRequests,
      CanNotFollowYourself,
      CanNotUnfollowYourself,
      HaveAlreadyFollowed,
      HaveNotFollowed,
      HaveAlreadyRequestedToFollow,
      NotFound => e

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

    request_class.next_request(user_id)&.enqueue(enqueue_location: 'Specified error', request_id: request&.id, error_class: e.class)
  rescue => e
    if e.class == Twitter::Error::Unauthorized
      handle_unauthorized_exception(e, user_id: user_id)
    end

    request.update(error_class: e.class, error_message: e.message.truncate(150))

    request_class.next_request(user_id)&.enqueue(enqueue_location: 'Something error', request_id: request&.id, error_class: e.class)
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

  class NotFound < StandardError
    def initialize(message = 'User not found.')
      super
    end
  end
end
