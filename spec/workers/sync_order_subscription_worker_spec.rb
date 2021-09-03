require 'rails_helper'

RSpec.describe SyncOrderSubscriptionWorker do
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id) }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:subscription) { 'subscription' }
    subject { worker.perform(order.id) }

    before do
      allow(Order).to receive(:find).with(order.id).and_return(order)
      allow(worker).to receive(:fetch_subscription).with(order.subscription_id).and_return(subscription)
    end

    it do
      expect(worker).to receive(:update_canceled_at).with(order, subscription)
      expect(worker).to receive(:update_trial_end).with(order, subscription)
      subject
    end
  end

  describe '#update_canceled_at' do
    let(:timestamp) { 1.second.ago.to_i }
    let(:subscription) { double('subscription', canceled_at: timestamp) }
    subject { worker.send(:update_canceled_at, order, subscription) }
    it do
      expect(worker).to receive(:send_message).with(order.id, [nil, Time.zone.at(timestamp)])
      subject
      order.reload
      expect(order.canceled_at).to eq(Time.zone.at(timestamp))
    end
  end

  describe '#update_trial_end' do
    let(:timestamp) { 1.hour.since.to_i }
    let(:subscription) { double('subscription', trial_end: timestamp) }
    subject { worker.send(:update_trial_end, order, subscription) }
    it do
      expect(worker).to receive(:send_message).with(order.id, [nil, timestamp])
      subject
      order.reload
      expect(order.trial_end).to eq(timestamp)
    end
  end
end
