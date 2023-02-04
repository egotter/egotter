# == Schema Information
#
# Table name: twitter_db_user_ids
#
#  id         :bigint(8)        not null, primary key
#  uid        :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_twitter_db_user_ids_on_uid  (uid) UNIQUE
#

module TwitterDB
  class UserId < ApplicationTwitterRecord
    validates :uid, presence: true, uniqueness: true
  end
end
