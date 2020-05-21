require 'active_support/concern'

module Concerns::TwitterUser::Dirty
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  # return:
  # {
  #    friends_count:   [111, 222]
  #    followers_count: [333, 444]
  #    friend_uids:     [[1, 2, 3], [3, 4, 5]]
  #    follower_uids:   [[1, 2, 3], [3, 4, 5]]
  #  }
  def diff(newer)
    older = self

    diff = Diff.from_record(older, newer)

    if Rails.env.development?
      logger.debug { "#{self.class}##{__method__} uid=#{uid} screen_name=#{screen_name} diff.keys=#{diff.keys}" }
    end

    diff
  end

  class Diff < Hash
    def initialize(hash)
      hash.each { |key, value| self[key] = value }
    end

    class << self
      def from_record(older, newer)
        array = []

        %i(friends_count followers_count friend_uids follower_uids).map do |attr|
          values = [older.send(attr), newer.send(attr)]
          values = values.map(&:sort) if %i(friend_uids follower_uids).include?(attr)
          array << [attr, values]
        end

        hash = array.to_h
        hash.reject! { |_, v| v[0] == v[1] }

        new(hash)
      end
    end
  end
end
