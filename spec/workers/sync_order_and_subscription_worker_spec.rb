require 'rails_helper'

RSpec.describe SyncOrderAndSubscriptionWorker do
  let(:user) { create(:user) }
  let(:order) { create(:order, user: user) }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:subscription) { double('subscription', trial_end: Time.zone.now.to_i) }
    subject { worker.perform(order.id) }

    before do
      allow(Order).to receive(:find).with(order.id).and_return(order)
    end

    it do
      expect(Stripe::Subscription).to receive(:update).with(order.subscription_id, metadata: {order_id: order.id}).and_return(subscription)
      subject
      order.reload
      expect(order.trial_end).to eq(subscription.trial_end)
    end
  end
end
