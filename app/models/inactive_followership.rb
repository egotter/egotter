# == Schema Information
#
# Table name: inactive_followerships
#
#  id           :integer          not null, primary key
#  from_uid     :integer          not null
#  follower_uid :integer          not null
#  sequence     :integer          not null
#
# Indexes
#
#  index_inactive_followerships_on_follower_uid  (follower_uid)
#  index_inactive_followerships_on_from_uid      (from_uid)
#

class InactiveFollowership < ApplicationRecord
  belongs_to :twitter_user, primary_key: :uid, foreign_key: :from_uid
  belongs_to :inactive_follower, primary_key: :uid, foreign_key: :follower_uid, class_name: 'TwitterDB::User'

  def self.import_from!(from_uid, follower_uids)
    followerships = follower_uids.map.with_index { |follower_uid, i| [from_uid.to_i, follower_uid.to_i, i] }

    ActiveRecord::Base.transaction do
      delete_all(from_uid: from_uid) if exists?(from_uid: from_uid)
      import(%i(from_uid follower_uid sequence), followerships, validate: false, timestamps: false)
    end
  end
end
