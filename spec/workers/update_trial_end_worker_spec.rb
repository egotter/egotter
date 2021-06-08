require 'rails_helper'

RSpec.describe UpdateTrialEndWorker do
  let(:user) { create(:user, with_orders: true) }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:order) { user.orders.last }
    let(:subscription) { double('subscription', trial_end: Time.zone.now.to_i) }
    let(:customer) { double('customer', email: 'a@b.com') }
    subject { worker.perform(order.id) }

    before do
      allow(Order).to receive(:find).with(order.id).and_return(order)
      allow(order).to receive(:fetch_stripe_subscription).and_return(subscription)
      allow(order).to receive(:fetch_stripe_customer).and_return(customer)
    end

    it do
      subject
      order.reload
      expect(order.trial_end).to eq(subscription.trial_end)
      expect(order.email).to eq(customer.email)
    end
  end
end
