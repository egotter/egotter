require 'active_support/concern'

module Concerns::TwitterUser::Dirty
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def diff(newer)
    older = self
    attrs = %i(friends_count followers_count friend_uids follower_uids)

    attrs.map do |attr|
      values = [older.send(attr), newer.send(attr)]
      values = values.map(&:sort) if attr.in?(%i(friend_uids follower_uids))

      logger.debug {"#{__method__} #{screen_name} #{attr} #{values.inspect}"}

      [attr, values]
    end.to_h.reject {|_, v| v[0] == v[1]}
  end
end
