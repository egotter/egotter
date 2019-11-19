require 'active_support/concern'

module Concerns::TwitterDB::User::Associations
  extend ActiveSupport::Concern

  class_methods do
    # This method makes the result unique.
    def where_and_order_by_field(uids:)
      where(uid: uids).sort_by {|user| uids.index(user.uid)}.tap do |users|
        unless uids.size == users.size
          CreateTwitterDBUserWorker.perform_async(uids - users.map(&:uid))
        end
      end
    end
  end

  included do
    default_options = {dependent: :destroy, validate: false, autosave: false}
    order_by_sequence_asc = -> { order(sequence: :asc) }

    with_options default_options.merge(primary_key: :uid, foreign_key: :uid) do |obj|
      obj.has_many :statuses,  order_by_sequence_asc, class_name: 'TwitterDB::Status'
      obj.has_many :favorites, order_by_sequence_asc, class_name: 'TwitterDB::Favorite'
      obj.has_many :mentions,  order_by_sequence_asc, class_name: 'TwitterDB::Mention'
    end

    with_options default_options.merge(primary_key: :uid, foreign_key: :from_uid) do |obj|
      obj.has_many :unfriendships,     order_by_sequence_asc
      obj.has_many :unfollowerships,   order_by_sequence_asc
      obj.has_many :block_friendships, order_by_sequence_asc
    end

    with_options default_options.merge(class_name: 'TwitterDB::User') do |obj|
      obj.has_many :unfriends,     through: :unfriendships
      obj.has_many :unfollowers,   through: :unfollowerships
      obj.has_many :block_friends, through: :block_friendships
    end
  end
end
