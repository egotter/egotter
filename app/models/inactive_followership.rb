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
  include Concerns::Followership::Importable

  with_options(primary_key: :uid, optional: true) do |obj|
    obj.belongs_to :twitter_user, foreign_key: :from_uid
    obj.belongs_to :inactive_follower, foreign_key: :follower_uid, class_name: 'TwitterDB::User'
  end

  class << self
    def import_by!(twitter_user:)
      uids = twitter_user.calc_inactive_follower_uids
      import_from!(twitter_user.uid, uids)
      uids
    end
  end
end
