module StripeDB
  class Plan < ActiveRecord::Base

    validates :plan_key, inclusion: { in: %w(basic pro) }

    FREE_PLAN_NAME = I18n.t('stripe.plans.names.free')

    def price_label
      "#{amount}#{I18n.t('stripe.currency.jpy')} / #{I18n.t('stripe.interval.monthly')}"
    end
  end
end
