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
end
