require 'active_support/concern'

module Concerns::TwitterUser::Dirty
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  # return:
  # {
  #    friends_count: [before ,after],
  #    followers_count: [before, after],
  #    friend_uids: [[before], [after]],
  #    follower_uids: [[before], [after]]
  #  }
  def diff(newer)
    older = self

    %i(friends_count followers_count friend_uids follower_uids).map do |attr|
      values = [older.send(attr), newer.send(attr)]
      values = values.map(&:sort) if attr.in?(%i(friend_uids follower_uids))

      logger.debug {"#{self.class}##{__method__} uid=#{uid} screen_name=#{screen_name} attr=#{attr} values[0]=#{values[0].inspect} values[1]=#{values[1].inspect}"}

      [attr, values]
    end.to_h.reject {|_, v| v[0] == v[1]}
  end
end
