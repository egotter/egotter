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
      expect(worker).to receive(:cancel_order).with(order, subscription)
      expect(worker).to receive(:end_trial_period).with(order, subscription)
      subject
    end
  end

  describe '#cancel_order' do
    let(:timestamp) { 1.second.ago.to_i }
    let(:subscription) { double('subscription', canceled_at: timestamp) }
    subject { worker.send(:cancel_order, order, subscription) }
    it do
      expect(worker).to receive(:send_message).
          with('cancel_order', order, hash_including('canceled_at' => instance_of(Array)))
      subject
      order.reload
      expect(order.canceled_at).to eq(Time.zone.at(timestamp))
    end
  end

  describe '#end_trial_period' do
    let(:timestamp) { 1.hour.since.to_i }
    let(:subscription) { double('subscription', trial_end: timestamp) }
    subject { worker.send(:end_trial_period, order, subscription) }
    it do
      expect(worker).to receive(:send_message).
          with('end_trial_period', order, hash_including('trial_end' => instance_of(Array)))
      subject
      order.reload
      expect(order.trial_end).to eq(timestamp)
    end
  end

  describe '#send_message' do
    subject { worker.send(:send_message, 'location', order, {}) }
    it do
      expect(SlackMessage).to receive(:create).with(channel: 'orders_sync', message: instance_of(String))
      expect(SlackBotClient).to receive_message_chain(:channel, :post_message).with('orders_sync').with(instance_of(String))
      subject
    end
  end
end
