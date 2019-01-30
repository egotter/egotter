# == Schema Information
#
# Table name: one_sided_followerships
#
#  id           :bigint(8)        not null, primary key
#  from_uid     :bigint(8)        not null
#  follower_uid :bigint(8)        not null
#  sequence     :integer          not null
#
# Indexes
#
#  index_one_sided_followerships_on_follower_uid  (follower_uid)
#  index_one_sided_followerships_on_from_uid      (from_uid)
#

class OneSidedFollowership < ApplicationRecord
  include Concerns::Followership::Importable

  belongs_to :twitter_user, primary_key: :uid, foreign_key: :from_uid
  belongs_to :one_sided_follower, primary_key: :uid, foreign_key: :follower_uid, class_name: 'TwitterDB::User'
end
