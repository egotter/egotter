# == Schema Information
#
# Table name: followerships
#
#  id           :integer          not null, primary key
#  from_id      :integer          not null
#  follower_uid :integer          not null
#  sequence     :integer          not null
#
# Indexes
#
#  index_followerships_on_follower_uid              (follower_uid)
#  index_followerships_on_from_id                   (from_id)
#  index_followerships_on_from_id_and_follower_uid  (from_id,follower_uid) UNIQUE
#

module TwitterDB2
  class Followership < ActiveRecord::Base
    self.table_name = 'twitter_db_followerships'

    belongs_to :user, primary_key: :uid, class_name: 'TwitterDB2::User'
    belongs_to :follower, primary_key: :uid, foreign_key: :follower_uid, class_name: 'TwitterDB2::User'

    def self.import_from!(user_uid, follower_uids)
      followerships = follower_uids.map.with_index { |follower_uid, i| [user_uid, follower_uid, i] }

      ActiveRecord::Base.transaction do
        delete_all(user_uid: user_uid)
        import(%i(user_uid follower_uid sequence), followerships, validate: false, timestamps: false)
      end
    end
  end
end
