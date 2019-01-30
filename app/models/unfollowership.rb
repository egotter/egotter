# == Schema Information
#
# Table name: unfollowerships
#
#  id           :bigint(8)        not null, primary key
#  from_uid     :bigint(8)        not null
#  follower_uid :bigint(8)        not null
#  sequence     :integer          not null
#
# Indexes
#
#  index_unfollowerships_on_follower_uid  (follower_uid)
#  index_unfollowerships_on_from_uid      (from_uid)
#

class Unfollowership < ApplicationRecord
  include Concerns::Followership::Importable

  belongs_to :twitter_user, primary_key: :uid, foreign_key: :from_uid
  belongs_to :unfollower, primary_key: :uid, foreign_key: :follower_uid, class_name: 'TwitterDB::User'
end
