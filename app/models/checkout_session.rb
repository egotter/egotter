# == Schema Information
#
# Table name: checkout_sessions
#
#  id                         :bigint(8)        not null, primary key
#  user_id                    :bigint(8)        not null
#  stripe_checkout_session_id :string(191)      not null
#  properties                 :json
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
# Indexes
#
#  index_checkout_sessions_on_created_at  (created_at)
#  index_on_user_id_and_scs_id            (user_id,stripe_checkout_session_id) UNIQUE
#
class CheckoutSession < ApplicationRecord
  validates :user_id, presence: true
  validates :stripe_checkout_session_id, presence: true
end
