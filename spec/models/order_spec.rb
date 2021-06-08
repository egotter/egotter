require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:user) { create(:user) }

  describe '.create_by_webhook!' do
    let(:metadata) { double('metadata', price: 123) }
    let(:checkout_session) { double('checkout_session', id: 'cs_111', client_reference_id: user.id, customer_email: 'a@b.com', metadata: metadata, customer: 'cus_222', subscription: 'sub_333') }
    subject { described_class.create_by_webhook!(checkout_session) }
    it { expect { subject }.to change { Order.all.size }.by(1) }
  end

  describe '#sync_stripe_attributes!' do
    let(:order) { create(:order, user_id: user.id) }
    let(:customer) { double('customer', email: 'a@b.com') }
    let(:subscription) { double('subscription', name: 'name', price: 'price', canceled_at: nil, trial_end: Time.zone.now.to_i) }
    subject { order.sync_stripe_attributes! }
    before do
      allow(order).to receive(:fetch_stripe_customer).and_return(customer)
      allow(order).to receive(:fetch_stripe_subscription).and_return(subscription)
    end
    it do
      subject
      order.reload
      expect(order.email).to eq(customer.email)
      expect(order.trial_end).to eq(subscription.trial_end)
    end
  end

  describe '#cancel!' do
    let(:order) { create(:order, user_id: user.id, subscription_id: 'sub', canceled_at: nil) }
    let(:canceled_at) { Time.zone.now }
    let(:subscription) { double('subscription', canceled_at: Time.zone.now) }
    subject { order.cancel! }
    before { allow(Stripe::Subscription).to receive(:delete).with('sub').and_return(subscription) }

    it do
      subject
      expect(order.canceled_at).to be_present
    end
  end
end
