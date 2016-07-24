require 'active_support/concern'

module Concerns::TwitterUser::Dirty
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def diff(other, options = {})
    older, newer = self, other

    keys = %i(friends_count followers_count friend_uids follower_uids)
    keys.select! { |k| k.in?(options[:only]) } if options.has_key?(:only)

    keys.map do |key|
      value = [older.send(key), newer.send(key)]
      value = value.map { |v| v.sort } if key.in?(%i(friend_uids follower_uids))
      [key, value]
    end.to_h.reject { |_, v| v[0] == v[1] }
  end
end