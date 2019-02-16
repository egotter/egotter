# == Schema Information
#
# Table name: orders
#
#  id                      :bigint(8)        not null, primary key
#  follow_requests_count   :integer          default(0), not null
#  search_count            :integer          default(0), not null
#  unfollow_requests_count :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  customer_id             :string(191)
#  subscription_id         :string(191)
#  user_id                 :integer          not null
#
# Indexes
#
#  index_orders_on_user_id  (user_id)
#

class Order < ApplicationRecord
  belongs_to :user

  def stripe_customer
    ::Stripe::Customer.retrieve(customer_id)
  end

  def stripe_subscription
    ::Stripe::Subscription.retrieve(subscription_id)
  end

  def end_date
    (created_at + 30.days).to_date
  end

  def expired?
    customer_id.nil? || subscription_id.nil? || end_date < Time.zone.now
  end
end
