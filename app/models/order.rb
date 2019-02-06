# == Schema Information
#
# Table name: orders
#
#  id         :bigint(8)        not null, primary key
#  amount     :integer          not null
#  email      :string(191)      not null
#  token      :string(191)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
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
