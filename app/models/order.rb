# == Schema Information
#
# Table name: orders
#
#  id                      :bigint(8)        not null, primary key
#  user_id                 :integer          not null
#  email                   :string(191)
#  name                    :string(191)
#  price                   :integer
#  search_count            :integer          default(0), not null
#  follow_requests_count   :integer          default(0), not null
#  unfollow_requests_count :integer          default(0), not null
#  customer_id             :string(191)
#  subscription_id         :string(191)
#  canceled_at             :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_orders_on_user_id  (user_id)
#

class Order < ApplicationRecord
  belongs_to :user

  BASIC_PLAN_ID = ENV['STRIPE_BASIC_PLAN_ID']
  TRIAL_DAYS = 14

  scope :unexpired, -> do
    where('customer_id is not null AND subscription_id is not null AND canceled_at is null')
  end

  def stripe_customer
    @stripe_customer ||= (customer_id ? Customer.new(::Stripe::Customer.retrieve(customer_id)) : nil)
  end

  def stripe_subscription
    @stripe_subscription ||= (subscription_id ? Subscription.new(::Stripe::Subscription.retrieve(subscription_id)) : nil)
  end

  def purchase_failed?
    customer_id.nil? || subscription_id.nil?
  end

  def cancel!
    update!(canceled_at: Subscription.new(::Stripe::Subscription.delete(subscription_id)).canceled_at)
  end

  class Customer
    def initialize(customer)
      @customer = customer
    end

    def email
      @customer.email
    end

    def created_at
      Time.zone.at(@customer.created)
    end
  end

  class Subscription
    def initialize(subscription)
      @subscription = subscription
    end

    def name
      @subscription.items.data[0].plan.nickname
    end

    def price
      @subscription.items.data[0].plan.amount
    end

    def created_at
      Time.zone.at(@subscription.created)
    end

    def canceled_at
      @subscription.canceled_at ? Time.zone.at(@subscription.canceled_at) : nil
    end
  end
end
