require 'rails_helper'

RSpec.describe ProcessStripeChargeSucceededEventWorker do
  let(:worker) { described_class.new }
  let(:customer_id) { 'cus_xxx' }
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id, customer_id: customer_id) }

  describe '#perform' do
    subject { worker.perform(customer_id) }
    before do
      allow(Order).to receive(:where).with(customer_id: customer_id, canceled_at: nil, charge_failed_at: nil).and_return(orders)
    end

    context 'No order' do
      let(:orders) { [] }
      it do
        expect(worker).to receive(:send_error_message).with(/^\[To Be Fixed\] Cannot find/, anything)
        subject
      end
    end

    context 'A order' do
      let(:orders) { [order] }
      before { allow(order).to receive(:user).and_return(user) }

      context 'The user has a valid subscription' do
        before { allow(user).to receive(:has_valid_subscription?).and_return(true) }
        it do
          expect(worker).to receive(:send_message).with('Success', anything)
          subject
        end
      end

      context 'The user does not have a valid subscription' do
        before { allow(user).to receive(:has_valid_subscription?).and_return(false) }
        it do
          expect(worker).to receive(:send_error_message).with(/\[To Be Fixed\] The customer doesn't/, anything)
          subject
        end
      end
    end

    context 'More than two order' do
      let(:orders) { [order, order] }
      it do
        expect(worker).to receive(:send_error_message).with(/^\[To Be Fixed\] More than/, anything)
        subject
      end
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
