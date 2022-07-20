# == Schema Information
#
# Table name: stripe_webhook_logs
#
#  id         :bigint(8)        not null, primary key
#  controller :string(191)
#  action     :string(191)
#  path       :string(191)
#  event_id   :string(191)
#  event_type :string(191)
#  event_data :json
#  ip         :string(191)
#  method     :string(191)
#  status     :integer
#  user_agent :string(191)
#  created_at :datetime         not null
#
# Indexes
#
#  index_stripe_webhook_logs_on_created_at  (created_at)
#
class StripeWebhookLog < ApplicationRecord
end
