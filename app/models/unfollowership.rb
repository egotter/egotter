# == Schema Information
#
# Table name: unfollowerships
#
#  from_uid     :integer          not null
#  follower_id  :integer          not null
#  follower_uid :integer          not null
#  sequence     :integer          not null
#
# Indexes
#
#  index_unfollowerships_on_follower_id                (follower_id)
#  index_unfollowerships_on_follower_uid               (follower_uid)
#  index_unfollowerships_on_from_uid                   (from_uid)
#  index_unfollowerships_on_from_uid_and_follower_id   (from_uid,follower_id) UNIQUE
#  index_unfollowerships_on_from_uid_and_follower_uid  (from_uid,follower_uid) UNIQUE
#

class Unfollowership < ActiveRecord::Base
  belongs_to :twitter_user
  belongs_to :unfollower, foreign_key: :follower_id, class_name: 'Follower'

  def self.import_from!(twitter_user)
    unfollowerships = twitter_user.calc_removed.map.with_index { |u, i| [u.id, u.uid.to_i, twitter_user.uid.to_i, i] }

    ActiveRecord::Base.transaction do
      delete_all(from_uid: twitter_user.uid)
      import(%i(follower_id follower_uid from_uid sequence), unfollowerships, validate: false, timestamps: false)
    end
  end
end
