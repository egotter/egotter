# == Schema Information
#
# Table name: forbidden_users
#
#  id          :integer          not null, primary key
#  screen_name :string(191)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_forbidden_users_on_created_at   (created_at)
#  index_forbidden_users_on_screen_name  (screen_name) UNIQUE
#

class NotFoundUser < ActiveRecord::Base
  validates_with Validations::ScreenNameValidator
end
