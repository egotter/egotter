class StripeSubscription

  def initialize(id)
    @data = Stripe::Subscription.retrieve(id)
  end

  def name
    @data.items.data[0].plan.nickname
  end

  def price
    @data.items.data[0].plan.amount
  end

  def tax_rate
    @data.default_tax_rates[0].percentage / 100.0
  end

  def trial_end
    @data.trial_end
  end

  def trial?
    Time.zone.now < Time.zone.at(@data.trial_end)
  end

  def created_at
    Time.zone.at(@data.created)
  end

  def canceled_at
    @data.canceled_at ? Time.zone.at(@data.canceled_at) : nil
  end
end
