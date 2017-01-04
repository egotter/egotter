# == Schema Information
#
# Table name: followerships
#
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

class Followership < ActiveRecord::Base
  belongs_to :twitter_user, primary_key: :id, foreign_key: :from_id
  # belongs_to :tmp_follower, primary_key: :uid, foreign_key: :follower_uid, class_name: 'TwitterDB::User'

  def self.import_from!(twitter_user)
    followerships = twitter_user.followers.pluck(:uid).map.with_index { |uid, i| [uid, twitter_user.id, i] }

    ActiveRecord::Base.transaction do
      delete_all(from_id: twitter_user.id)
      import(%i(follower_uid from_id sequence), followerships, validate: false, timestamps: false)

      twitter_user.assign_attributes(followers_size: followerships.size)
      twitter_user.save! if twitter_user.changed?
    end
  end
end
