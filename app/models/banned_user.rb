# == Schema Information
#
# Table name: banned_users
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)        not null
#  created_at :datetime         not null
#
# Indexes
#
#  index_banned_users_on_created_at  (created_at)
#  index_banned_users_on_user_id     (user_id) UNIQUE
#
class BannedUser < ApplicationRecord
  belongs_to :user
end
