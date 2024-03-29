# == Schema Information
#
# Table name: orders
#
#  id                      :bigint(8)        not null, primary key
#  ahoy_visit_id           :bigint(8)
#  user_id                 :integer          not null
#  email                   :string(191)
#  name                    :string(191)
#  price                   :integer
#  tax_rate                :decimal(4, 2)
#  trial_end               :integer
#  search_count            :integer          default(0), not null
#  follow_requests_count   :integer          default(0), not null
#  unfollow_requests_count :integer          default(0), not null
#  checkout_session_id     :string(191)
#  customer_id             :string(191)
#  subscription_id         :string(191)
#  cancel_source           :string(191)
#  canceled_at             :datetime
#  charge_failed_at        :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_orders_on_user_id  (user_id)
#

class Order < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
  validates :name, presence: true
  validates :customer_id, presence: true
  validates :subscription_id, presence: true

  # TODO Other validations

  BASIC_PLAN_ID = ENV['STRIPE_BASIC_PLAN_ID']
  BASIC_PLAN_PRICE_ID = ENV['STRIPE_BASIC_PLAN_PRICE_ID']
  BASIC_PLAN_MONTHLY_BASIS = {
      'monthly-basis-1' => 600,
      'monthly-basis-3' => 873,
      'monthly-basis-6' => 1709,
      'monthly-basis-12' => 3236,
  }
  # 3 months: 300 * 3 * 0.97 * 1.1 = 960
  # 6 months: 300 * 6 * 0.95 * 1.1 = 1881
  # 12 months: 300 * 12 * 0.90 * 1.1 = 3564
  BASIC_PLAN_MONTHLY_BASIS_TAX_INCLUDED = {
      'monthly-basis-1' => 660,
      'monthly-basis-3' => 960,
      'monthly-basis-6' => 1880,
      'monthly-basis-12' => 3560,
  }
  BASIC_PLAN_MONTHLY_BASIS_REGULAR_TAX_INCLUDED = {
      'monthly-basis-1' => 660,
      'monthly-basis-3' => 660 * 3,
      'monthly-basis-6' => 660 * 6,
      'monthly-basis-12' => 660 * 12,
  }
  BASIC_PLAN_MONTHLY_BASIS_1_PRICE_ID = ENV['STRIPE_BASIC_PLAN_MONTHLY_BASIS_1_PRICE_ID']
  BASIC_PLAN_MONTHLY_BASIS_PRICE_IDS = {
      'monthly-basis-1' => ENV['STRIPE_BASIC_PLAN_MONTHLY_BASIS_1_PRICE_ID'],
      'monthly-basis-3' => ENV['STRIPE_BASIC_PLAN_MONTHLY_BASIS_3_PRICE_ID'],
      'monthly-basis-6' => ENV['STRIPE_BASIC_PLAN_MONTHLY_BASIS_6_PRICE_ID'],
      'monthly-basis-12' => ENV['STRIPE_BASIC_PLAN_MONTHLY_BASIS_12_PRICE_ID'],
  }
  TAX_RATE_ID = ENV['STRIPE_TAX_RATE_ID']
  TAX_RATE = 0.1
  PRICE = 300
  REGULAR_PRICE = 600
  REGULAR_PRICE_TAX_INCLUDED = 660
  DISCOUNT_PRICE = 300
  DISCOUNT_PRICE_TAX_INCLUDED = 330
  TRIAL_DAYS = 14
  COUPON_ID = ENV['STRIPE_COUPON_ID']
  FREE_PLAN_USERS_LIMIT = 100
  BASIC_PLAN_USERS_LIMIT = 10000
  FREE_PLAN_BLOCKERS_LIMIT = 10
  BASIC_PLAN_BLOCKERS_LIMIT = 10000

  scope :unexpired, -> do
    where('customer_id is not null AND subscription_id is not null AND canceled_at is null')
  end

  class << self
    def create_by_checkout_session(checkout_session)
      # tax_rate = checkout_session.subscription.tax_percent / 100.0
      name = 'えごったー ベーシック'

      # The checkout_session doesn't have an email in #customer_email and #customer_details.email

      create!(
          user_id: checkout_session.client_reference_id,
          email: nil,
          name: name,
          price: checkout_session.metadata.price,
          tax_rate: 0.1,
          search_count: SearchCountLimitation::BASIC_PLAN,
          follow_requests_count: CreateFollowLimitation::BASIC_PLAN,
          unfollow_requests_count: 20,
          checkout_session_id: checkout_session.id,
          customer_id: checkout_session.customer,
          subscription_id: checkout_session.subscription
      )
    end

    def create_by_monthly_basis(checkout_session)
      months_count = checkout_session.metadata.months_count
      item_id = checkout_session.metadata.item_id
      price_id = BASIC_PLAN_MONTHLY_BASIS_PRICE_IDS[item_id]

      if price_id.blank?
        raise "price_id is blank checkout_session_id=#{checkout_session.id} months_count=#{months_count} item_id=#{item_id}"
      end

      subscription = Stripe::Subscription.create(
          customer: checkout_session.customer,
          items: [{price: price_id}],
          metadata: {user_id: checkout_session.client_reference_id, price: 0, months_count: months_count, item_id: item_id},
      )

      create!(
          user_id: checkout_session.client_reference_id,
          email: (checkout_session.customer_details.email rescue nil),
          name: checkout_session.metadata.name,
          price: checkout_session.metadata.price,
          tax_rate: 0.1,
          search_count: SearchCountLimitation::BASIC_PLAN,
          follow_requests_count: CreateFollowLimitation::BASIC_PLAN,
          unfollow_requests_count: 20,
          checkout_session_id: checkout_session.id,
          customer_id: checkout_session.customer,
          subscription_id: subscription.id,
      )
    end

    def create_by_shop_item(user, email, name, price, customer_id, subscription_id)
      create!(
          user_id: user.id,
          email: email,
          name: name,
          price: price,
          tax_rate: 0.1,
          search_count: SearchCountLimitation::BASIC_PLAN,
          follow_requests_count: CreateFollowLimitation::BASIC_PLAN,
          unfollow_requests_count: 20,
          checkout_session_id: nil,
          customer_id: customer_id,
          subscription_id: subscription_id,
          trial_end: Time.zone.now.to_i,
      )
    end

    def create_by_bank_transfer(user, stripe_customer)
      price_id = ENV['STRIPE_FREE_PAYMENT_PRICE_ID']
      price = 0
      months_count = 1
      order_name = "えごったー ベーシック #{months_count}ヶ月分"

      subscription = Stripe::Subscription.create(
          customer: stripe_customer.id,
          items: [{price: price_id}],
          metadata: {user_id: user.id, price: price, months_count: months_count},
      )

      order = Order.create!(
          user_id: user.id,
          email: '',
          name: order_name,
          price: price,
          tax_rate: 0.1,
          search_count: SearchCountLimitation::BASIC_PLAN,
          follow_requests_count: CreateFollowLimitation::BASIC_PLAN,
          unfollow_requests_count: 20,
          checkout_session_id: nil,
          customer_id: stripe_customer.id,
          subscription_id: subscription.id,
          trial_end: Time.zone.now.to_i,
      )

      Stripe::Subscription.update(subscription.id, {metadata: {order_id: order.id}})

      order
    end
  end

  def short_name
    if name.include?('（')
      name.split('（')[0]
    else
      name
    end
  end

  # For debugging
  def purchase_failed?
    customer_id.nil? || subscription_id.nil?
  end

  def trial_end_time
    Time.zone.at(trial_end)
  end

  def trial?
    !trial_end.nil? && Time.zone.now < trial_end_time
  end

  def end_trial!
    Stripe::Subscription.update(subscription_id, trial_end: 'now')
    update!(trial_end: Time.zone.now.to_i)
  end

  def canceled?
    canceled_at.present?
  end

  # If payment fails on the checkout page for a second or subsequent purchase, this method may be called for a previous order.
  def cancel!(source = nil)
    if canceled_at.present?
      Airbag.warn '#cancel! is called for an already canceled order', order_id: id, source: source
    end

    subscription = Stripe::Subscription.retrieve(subscription_id)

    if subscription.status == 'canceled'
      SendMessageToSlackWorker.perform_async(:orders_warning, "Subscription has already been canceled order_id=#{id} subscription_id=#{subscription_id} source=#{source}")
      update!(cancel_source: source, canceled_at: Time.zone.now)
    else
      subscription = Stripe::Subscription.cancel(subscription_id)
      update!(cancel_source: source, canceled_at: Time.zone.at(subscription.canceled_at))
    end
  rescue Stripe::InvalidRequestError => e
    if e.message&.include?('No such subscription')
      SendMessageToSlackWorker.perform_async(:orders_warning, "Subscription not found but OK exception=#{e.inspect} order_id=#{id} source=#{source}")
      update!(cancel_source: source, canceled_at: Time.zone.now)
    else
      raise
    end
  end
end
