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
      worker_class.perform_in(10.seconds.since, user_id) if request_class.unprocessed(user_id).exists?
    else
      raise TooManyRequests
    end
  rescue => e
    if e.class == Twitter::Error::Unauthorized
      handle_unauthorized_exception(e, user_id: user_id)
    elsif e.class == Twitter::Error::Forbidden
      handle_forbidden_exception(e, user_id: user_id)
    end

    logger.warn "#{e.class} #{e.message} #{user_id} #{request.inspect}"
    request.update(error_class: e.class, error_message: e.message.truncate(150))

    if [CanNotFollowYourself, CanNotUnfollowYourself, HaveAlreadyFollowed, HaveNotFollowed].include?(e.class)
      worker_class.perform_async(user_id) if request_class.unprocessed(user_id).exists?
    else
      worker_class.perform_in(Concerns::User::FollowAndUnfollow::Util.limit_interval.since, user_id)
    end
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
end
