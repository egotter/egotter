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

  VALID_PERIOD = 1800 # 30 minutes

  def valid_period?
    created_at > VALID_PERIOD.seconds.ago
  end

  class << self
    def expire_all(user_id)
      where(user_id: user_id).where('created_at > ?', VALID_PERIOD.seconds.ago).order(created_at: :desc).limit(3).each do |cs|
        if Stripe::Checkout::Session.retrieve(cs.stripe_checkout_session_id).status == 'open'
          Stripe::Checkout::Session.expire(cs.stripe_checkout_session_id)
        end
      end
    rescue => e
      Airbag.exception e, user_id: user_id
    end

    def latest_by(condition)
      order(created_at: :desc).find_by(condition)
    end
  end
end
