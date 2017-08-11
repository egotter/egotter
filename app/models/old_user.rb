# == Schema Information
#
# Table name: old_users
#
#  id          :integer          not null, primary key
#  uid         :integer          not null
#  screen_name :string(191)      not null
#  authorized  :boolean          default(FALSE), not null
#  secret      :string(191)      not null
#  token       :string(191)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_old_users_on_created_at   (created_at)
#  index_old_users_on_screen_name  (screen_name)
#  index_old_users_on_uid          (uid) UNIQUE
#

class OldUser < ActiveRecord::Base
  validates_with Validations::UidValidator
  validates_with Validations::ScreenNameValidator

  scope :authorized, -> { where(authorized: true) }

  def api_client
    ApiClient.instance(access_token: token, access_token_secret: secret)
  end
end
