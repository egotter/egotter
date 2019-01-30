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

  with_options(primary_key: :uid, optional: true) do |obj|
    obj.belongs_to :twitter_user, foreign_key: :from_uid
    obj.belongs_to :one_sided_follower, foreign_key: :follower_uid, class_name: 'TwitterDB::User'
  end

  class << self
    def import_by!(twitter_user:)
      uids = twitter_user.calc_one_sided_follower_uids
      import_from!(twitter_user.uid, uids)
      uids
    end
  end
end
