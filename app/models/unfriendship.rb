# == Schema Information
#
# Table name: unfriendships
#
#  from_uid   :integer          not null
#  friend_uid :integer          not null
#  sequence   :integer          not null
#
# Indexes
#
#  index_unfriendships_on_friend_uid  (friend_uid)
#  index_unfriendships_on_from_uid    (from_uid)
#

class Unfriendship < ActiveRecord::Base
  belongs_to :twitter_user

  def self.import_from!(twitter_user)
    unfriendships = twitter_user.calc_removing.map.with_index { |u, i| [u.uid.to_i, twitter_user.uid.to_i, i] }

    ActiveRecord::Base.transaction do
      delete_all(from_uid: twitter_user.uid)
      import(%i(friend_uid from_uid sequence), unfriendships, validate: false, timestamps: false)
    end
  end
end
