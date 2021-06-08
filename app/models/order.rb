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
  visitable :ahoy_visit

  validates :user_id, presence: true
  validates :name, presence: true
  validates :customer_id, presence: true
  validates :subscription_id, presence: true

  # TODO Other validations

  BASIC_PLAN_ID = ENV['STRIPE_BASIC_PLAN_ID']
  BASIC_PLAN_PRICE_ID = ENV['STRIPE_BASIC_PLAN_PRICE_ID']
  TAX_RATE_ID = ENV['STRIPE_TAX_RATE_ID']
  TAX_RATE = 0.1
  PRICE = 300
  REGULAR_PRICE = 600
  DISCOUNT_PRICE = 300
  TRIAL_DAYS = 14
  COUPON_ID = ENV['STRIPE_COUPON_ID']
  FREE_PLAN_USERS_LIMIT = 100
  BASIC_PLAN_USERS_LIMIT = 10000
  FREE_PLAN_BLOCKERS_LIMIT = 10
  BASIC_PLAN_BLOCKERS_LIMIT = 10000
  FREE_PLAN_TREND_TWEETS_LIMIT = 100
  BASIC_PLAN_TREND_TWEETS_LIMIT = 100000

  scope :unexpired, -> do
    where('customer_id is not null AND subscription_id is not null AND canceled_at is null')
  end

  class << self
    def create_by_webhook!(checkout_session)
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
          unfollow_requests_count: CreateUnfollowLimitation::BASIC_PLAN,
          checkout_session_id: checkout_session.id,
          customer_id: checkout_session.customer,
          subscription_id: checkout_session.subscription
      )
    end
  end

  def sync_stripe_attributes!
    if (customer = fetch_stripe_customer)
      self.email = customer.email
    end

    if (subscription = fetch_stripe_subscription)
      # self.name = subscription.name
      # self.price = subscription.price

      if subscription.canceled_at
        self.canceled_at = subscription.canceled_at
      end

      if trial_end.nil?
        self.trial_end = subscription.trial_end
      end
    end

    if changed?
      save!
      saved_changes.except('updated_at')
    else
      nil
    end
  rescue => e
    logger.warn "#{__method__}: #{e.inspect} order_id=#{id}"
    {exception: e}
  end

  def short_name
    if name.include?('（')
      name.split('（')[0]
    else
      name
    end
  end

  def fetch_stripe_customer
    customer_id ? StripeCustomer.new(customer_id) : nil
  end

  def fetch_stripe_subscription
    subscription_id ? StripeSubscription.new(subscription_id) : nil
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
    ::Stripe::Subscription.update(subscription_id, trial_end: 'now')
    update!(trial_end: Time.zone.now.to_i)
  end

  def canceled?
    canceled_at.present?
  end

  def cancel!(source = nil)
    subscription = ::Stripe::Subscription.delete(subscription_id)
    update!(canceled_at: Time.zone.at(subscription.canceled_at))
  rescue Stripe::InvalidRequestError => e
    if e.message&.include?('No such subscription')
      logger.warn "Subscription not found but OK: exception=#{e.inspect} source=#{source}"
      update!(canceled_at: Time.zone.now) if canceled_at.nil?
    else
      raise
    end
  end

  def charge_succeeded!
    update!(charge_failed_at: nil)
  end

  def charge_failed!
    update!(charge_failed_at: Time.zone.now)
  end
end
