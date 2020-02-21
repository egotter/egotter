# == Schema Information
#
# Table name: credential_tokens
#
#  id           :bigint(8)        not null, primary key
#  user_id      :integer          not null
#  token        :string(191)
#  secret       :string(191)
#  instance_id  :string(191)
#  device_token :string(191)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_credential_tokens_on_created_at  (created_at)
#  index_credential_tokens_on_user_id     (user_id) UNIQUE
#

class CredentialToken < ApplicationRecord
  belongs_to :user
end
