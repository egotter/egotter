require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:user) { create(:user) }

  describe '#sync_stripe_attributes!' do
    let(:order) { create(:order, user_id: user.id) }
    let(:customer) { double('customer', email: 'email') }
    let(:subscription) { double('subscription', name: 'name', price: 'price', canceled_at: nil, trial_end: Time.zone.now) }
    subject { order.sync_stripe_attributes! }
    before do
      allow(order).to receive(:stripe_customer).and_return(customer)
      allow(order).to receive(:stripe_subscription).and_return(subscription)
    end
    it do
      expect(order).to receive(:save!)
      expect(SlackClient).to receive_message_chain(:channel, :send_message).with('orders').with(instance_of(String))
      subject
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
