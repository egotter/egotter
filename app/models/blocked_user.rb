# == Schema Information
#
# Table name: blocked_users
#
#  id          :bigint(8)        not null, primary key
#  screen_name :string(191)
#  uid         :bigint(8)        not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_blocked_users_on_created_at  (created_at)
#  index_blocked_users_on_uid         (uid) UNIQUE
#

class BlockedUser < ApplicationRecord
  validates_with Validations::ScreenNameValidator
  validates_with Validations::UidValidator
end
