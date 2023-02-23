require 'rails_helper'

RSpec.describe ProcessStripeChargeSucceededEventWorker do
  let(:worker) { described_class.new }
  let(:customer_id) { 'cus_xxxx' }
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id, customer_id: customer_id) }

  describe '#perform' do
    subject { worker.perform(customer_id) }
    before do
      allow(Order).to receive(:where).with(customer_id: customer_id).and_return([order])
    end
    it do
      expect(worker).to receive(:send_message).with(/Success/, {user_id: user.id, customer_id: customer_id})
      subject
    end
  end

  describe '#send_message' do
    subject { worker.send(:send_message, 'msg', {props: true}) }
    it do
      expect(SlackBotClient).to receive_message_chain(:channel, :post_message).
          with('orders_charge_succeeded').with(/msg/)
      subject
    end
  end

  describe '#send_error_message' do
    subject { worker.send(:send_error_message, 'msg', {props: true}) }
    it do
      expect(worker).to receive(:send_message).with('msg', {props: true})
      expect(SendMessageToSlackWorker).to receive(:perform_async).with(:orders_warning, /msg/)
      subject
    end
  end
end
