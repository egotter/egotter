require 'active_support/concern'

module Concerns::WorkerUtils
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  UNAUTHORIZED_MESSAGES = [
    'Invalid or expired token.',
    "You have been blocked from viewing this user's profile.", # user_timeline, favorites
    'Could not authenticate you.',
    'Not authorized.'
  ]

  FORBIDDEN_MESSAGES = [
    'User has been suspended.',
    'Your account is suspended and is not permitted to access this feature.',
    "You are unable to follow more people at this time. Learn more <a href='http://support.twitter.com/articles/66885-i-can-t-follow-people-follow-limits'>here</a>.",
    'To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.',
    "You can't follow yourself."
  ]

  NOT_FOUND_MESSAGES = [
    'User not found.',
    'No user matches for specified terms.'
  ]

  def handle_unauthorized_exception(ex, user_id: -1, uid: -1, twitter_user_id: -1)
    if ex.message == 'Invalid or expired token.'
      User.find_by(id: user_id)&.update(authorized: false)
    end

    message = "#{ex.class} #{ex.message} #{user_id} #{uid} #{twitter_user_id}"
    UNAUTHORIZED_MESSAGES.include?(ex.message) ? logger.info(message) : logger.warn(message)
  end

  def handle_forbidden_exception(ex, user_id: -1, uid: -1, twitter_user_id: -1)
    message = "#{ex.class} #{ex.message} #{user_id} #{uid} #{twitter_user_id}"
    FORBIDDEN_MESSAGES.include?(ex.message) ? logger.info(message) : logger.warn(message)
  end

  def egotter_retry_in
    30.minutes + rand(10.minutes)
  end
end
