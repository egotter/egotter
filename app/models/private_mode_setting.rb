# == Schema Information
#
# Table name: private_mode_settings
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_private_mode_settings_on_created_at  (created_at)
#  index_private_mode_settings_on_user_id     (user_id) UNIQUE
#
class PrivateModeSetting < ApplicationRecord
  validates :user_id, uniqueness: true

  class << self
    def specified?(uid)
      (user = User.select(:id).find_by(uid: uid)) &&
          where(user_id: user.id).exists?
    end
  end
end
