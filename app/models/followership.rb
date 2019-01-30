# == Schema Information
#
# Table name: followerships
#
#  id           :bigint(8)        not null, primary key
#  from_id      :integer          not null
#  follower_uid :bigint(8)        not null
#  sequence     :integer          not null
#
# Indexes
#
#  index_followerships_on_follower_uid              (follower_uid)
#  index_followerships_on_from_id                   (from_id)
#  index_followerships_on_from_id_and_follower_uid  (from_id,follower_uid) UNIQUE
#

class Followership < ApplicationRecord
  with_options(optional: true) do |obj|
    obj.belongs_to :twitter_user, primary_key: :id, foreign_key: :from_id
    obj.belongs_to :follower, primary_key: :uid, foreign_key: :follower_uid, class_name: 'TwitterDB::User'
  end

  def self.import_from!(from_id, follower_uids)
    followerships = follower_uids.map.with_index { |follower_uid, i| [from_id, follower_uid.to_i, i] }

    ActiveRecord::Base.transaction do
      where(from_id: from_id).delete_all if exists?(from_id: from_id)
      import(%i(from_id follower_uid sequence), followerships, validate: false, timestamps: false)
    end
  end
end
