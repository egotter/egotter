class StripeCustomer

  def initialize(id)
    @customer = Stripe::Customer.retrieve(id)
  end

  def email
    @customer.email
  end

  def created_at
    Time.zone.at(@customer.created)
  end

  def invoices(limit: 3)
    Stripe::Invoice.list(customer: @customer, limit: limit).data
  end

  def charges(limit: 3)
    Stripe::Charge.list(customer: @customer, limit: limit).data
  end
end
