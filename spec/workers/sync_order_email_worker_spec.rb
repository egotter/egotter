require 'rails_helper'

RSpec.describe SyncOrderEmailWorker do
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id) }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:new_email) { 'new@example.com' }
    subject { worker.perform(order.id) }

    before do
      allow(Order).to receive(:find).with(order.id).and_return(order)
      allow(worker).to receive(:fetch_customer_email).with(order.customer_id).and_return(new_email)
    end

    it do
      expect(worker).to receive(:send_message).with(order)
      subject
      order.reload
      expect(order.email).to eq(new_email)
    end

    context 'The order has an email' do
      before { order.email = 'info@example.com' }
      it do
        expect(worker).not_to receive(:send_message)
        subject
        order.reload
        expect(order.email).to eq('info@example.com')
      end
    end
  end

  describe '#send_message' do
    subject { worker.send(:send_message, order) }
    it do
      expect(SlackMessage).to receive(:create).with(channel: 'orders_sync', message: instance_of(String))
      expect(SlackBotClient).to receive_message_chain(:channel, :post_message).with('orders_sync').with(instance_of(String))
      subject
    end
  end
end
