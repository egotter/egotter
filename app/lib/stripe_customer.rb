class StripeCustomer

  def initialize(id)
    @data = Stripe::Customer.retrieve(id)
  end

  def email
    @data.email
  end

  def created_at
    Time.zone.at(@data.created)
  end

  def invoices(limit: 3)
    Stripe::Invoice.list(customer: @data, limit: limit).data
  end

  def charges(limit: 3)
    Stripe::Charge.list(customer: @data, limit: limit).data
  end
end
