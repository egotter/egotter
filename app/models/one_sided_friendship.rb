# == Schema Information
#
# Table name: one_sided_friendships
#
#  id         :bigint(8)        not null, primary key
#  from_uid   :bigint(8)        not null
#  friend_uid :bigint(8)        not null
#  sequence   :integer          not null
#
# Indexes
#
#  index_one_sided_friendships_on_friend_uid  (friend_uid)
#  index_one_sided_friendships_on_from_uid    (from_uid)
#

class OneSidedFriendship < ApplicationRecord
  include Concerns::Friendship::Importable

  with_options(primary_key: :uid, optional: true) do |obj|
    obj.belongs_to :twitter_user, foreign_key: :from_uid
    obj.belongs_to :one_sided_friend, foreign_key: :friend_uid, class_name: 'TwitterDB::User'
  end

  class << self
    def import_by!(twitter_user:)
      uids = twitter_user.calc_one_sided_friend_uids
      import_from!(twitter_user.uid, uids)
      uids
    end
  end
end
