require 'active_support/concern'

module Concerns::TwitterUser::Dirty
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def diff(newer, options = {})
    older = self

    keys = %i(friends_count followers_count friend_uids follower_uids)
    keys.select! { |k| k.in?(options[:only]) } if options.has_key?(:only)

    keys.map do |key|
      values = [older.send(key), newer.send(key)]
      values = values.map(&:sort) if key.in?(%i(friend_uids follower_uids))
      [key, values]
    end.to_h.reject { |_, v| v[0] == v[1] }
  end
end