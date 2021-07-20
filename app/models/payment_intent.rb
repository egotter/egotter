# == Schema Information
#
# Table name: payment_intents
#
#  id                       :bigint(8)        not null, primary key
#  user_id                  :bigint(8)        not null
#  stripe_payment_intent_id :string(191)      not null
#  expiry_date              :datetime         not null
#  succeeded_at             :datetime
#  canceled_at              :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
# Indexes
#
#  index_payment_intents_on_stripe_payment_intent_id  (stripe_payment_intent_id) UNIQUE
#  index_payment_intents_on_user_id                   (user_id)
#
class PaymentIntent < ApplicationRecord
  belongs_to :user

  attr_writer :stripe_payment_intent

  def stripe_payment_intent
    @stripe_payment_intent = Stripe::PaymentIntent.retrieve(stripe_payment_intent_id) unless @stripe_payment_intent
    @stripe_payment_intent
  end

  scope :accepting_bank_transfer, -> (user) do
    where(user_id: user.id).where('expiry_date > ?', Time.zone.now).where(succeeded_at: nil).where(canceled_at: nil)
  end

  def succeeded?
    !succeeded_at.nil?
  end

  def canceled?
    !canceled_at.nil?
  end

  def transfer_destination_account
    if (next_action = stripe_payment_intent.next_action)
      bank_instructions = next_action.display_bank_transfer_instructions
      address = bank_instructions.financial_addresses[0].zengin
      {
          amount_remaining: bank_instructions.amount_remaining,
          account_holder_name: address.account_holder_name,
          account_number: address.account_number,
          account_type: address.account_type,
          bank_code: address.bank_code,
          bank_name: address.bank_name,
          branch_code: address.branch_code,
          branch_name: address.branch_name,
      }
    else
      {}
    end
  end

  def payment_status
    stripe_payment_intent.status
  end

  class << self
    def create_with_stripe_payment_intent(user)
      intent = StripePaymentIntent.create(user)

      # TODO Cancel this intent after 7 days
      create(user_id: user.id, stripe_payment_intent_id: intent.id, stripe_payment_intent: intent, expiry_date: 7.days.since)
    end
  end
end
