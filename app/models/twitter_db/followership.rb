# == Schema Information
#
# Table name: twitter_db_followerships
#
#  id           :bigint(8)        not null, primary key
#  follower_uid :bigint(8)        not null
#  sequence     :integer          not null
#  user_uid     :bigint(8)        not null
#
# Indexes
#
#  index_twitter_db_followerships_on_follower_uid               (follower_uid)
#  index_twitter_db_followerships_on_user_uid                   (user_uid)
#  index_twitter_db_followerships_on_user_uid_and_follower_uid  (user_uid,follower_uid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (follower_uid => twitter_db_users.uid)
#  fk_rails_...  (user_uid => twitter_db_users.uid)
#

module TwitterDB
  class Followership < ApplicationRecord
    with_options(primary_key: :uid, class_name: 'TwitterDB::User', optional: true) do |obj|
      obj.belongs_to :user
      obj.belongs_to :follower, foreign_key: :follower_uid
    end

    def self.import_from!(user_uid, follower_uids)
      followerships = follower_uids.map.with_index { |follower_uid, i| [user_uid, follower_uid, i] }

      ActiveRecord::Base.transaction do
        where(user_uid: user_uid).delete_all if exists?(user_uid: user_uid)
        import(%i(user_uid follower_uid sequence), followerships, validate: false, timestamps: false)
      end
    end
  end
end
