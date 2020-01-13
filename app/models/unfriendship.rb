# == Schema Information
#
# Table name: unfriendships
#
#  id         :bigint(8)        not null, primary key
#  from_uid   :bigint(8)        not null
#  friend_uid :bigint(8)        not null
#  sequence   :integer          not null
#
# Indexes
#
#  index_unfriendships_on_friend_uid  (friend_uid)
#  index_unfriendships_on_from_uid    (from_uid)
#

class Unfriendship < ApplicationRecord
  include Concerns::Friendship::Importable

  with_options(primary_key: :uid, optional: true) do |obj|
    obj.belongs_to :twitter_user, foreign_key: :from_uid
    obj.belongs_to :unfriend, foreign_key: :friend_uid, class_name: 'TwitterDB::User'
  end

  class << self
    # TODO Want to remove later
    def import_by!(twitter_user:)
      uids = twitter_user.calc_unfriend_uids
      import_from!(twitter_user.uid, uids)
      uids
    end
  end
end
