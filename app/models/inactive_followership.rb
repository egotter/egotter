# == Schema Information
#
# Table name: inactive_followerships
#
#  id           :bigint(8)        not null, primary key
#  from_uid     :bigint(8)        not null
#  follower_uid :bigint(8)        not null
#  sequence     :integer          not null
#
# Indexes
#
#  index_inactive_followerships_on_follower_uid  (follower_uid)
#  index_inactive_followerships_on_from_uid      (from_uid)
#

class InactiveFollowership < ApplicationRecord

  with_options(primary_key: :uid, optional: true) do |obj|
    obj.belongs_to :twitter_user, foreign_key: :from_uid
    obj.belongs_to :inactive_follower, foreign_key: :follower_uid, class_name: 'TwitterDB::User'
  end

  class << self
    def delete_by_uid(uid)
      where(from_uid: uid).delete_all if exists?(from_uid: uid)
    end
  end
end
