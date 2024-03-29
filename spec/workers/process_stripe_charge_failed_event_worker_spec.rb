require 'rails_helper'

RSpec.describe ProcessStripeChargeFailedEventWorker do
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
      let(:customer) { create(:customer, user_id: user.id, stripe_customer_id: customer_id) }
      let(:checkout_session) { create(:checkout_session, user_id: user.id) }

      before do
        allow(Customer).to receive(:latest_by).with(stripe_customer_id: customer_id).and_return(customer)
        allow(CheckoutSession).to receive(:latest_by).with(user_id: user.id).and_return(checkout_session)
      end

      context 'The checkout session is valid' do
        before { allow(checkout_session).to receive(:valid_period?).and_return(true) }
        it do
          expect(worker).to receive(:send_message).with('The customer probably failed to enter card details', anything)
          subject
        end
      end

      context 'The checkout session is NOT valid' do
        before { allow(checkout_session).to receive(:valid_period?).and_return(false) }
        it do
          expect(worker).to receive(:send_error_message).with('[To Be Fixed] There is not a order for to be canceled', anything)
          subject
        end
      end
    end

    context 'A order' do
      let(:orders) { [order] }
      it do
        expect(order).to receive(:update!).with(charge_failed_at: instance_of(ActiveSupport::TimeWithZone))
        expect(order).to receive(:cancel!).with('webhook')
        expect(worker).to receive(:send_message).with('Success', anything)
        subject
      end
    end

    context 'More than two order' do
      let(:orders) { [order, order] }
      it do
        expect(worker).to receive(:send_error_message).with('[To Be Fixed] There are more than two orders for to be canceled', anything)
        subject
      end
    end

    context 'An error is raised' do
      let(:orders) { nil }
      let(:error) { RuntimeError.new }
      before do
        allow(Order).to receive(:where).with(anything).and_raise(error)
      end
      it do
        expect(Airbag).to receive(:exception).with(error, customer_id: customer_id, options: {})
        expect(worker).to receive(:send_error_message).with('[To Be Fixed] A fatal error occurred', customer_id: customer_id, options: {})
        subject
      end
    end
  end

  describe '#send_message' do
    subject { worker.send(:send_message, 'msg', {props: true}) }
    it do
      expect(SendOrderMessageToSlackWorker).to receive(:perform_async).with(:orders_charge_failed, /msg/)
      subject
    end
  end

  describe '#send_error_message' do
    subject { worker.send(:send_error_message, 'msg', {props: true}) }
    it do
      expect(worker).to receive(:send_message).with('msg', {props: true})
      expect(SendOrderMessageToSlackWorker).to receive(:perform_async).with(:orders_warning, /msg/)
      subject
    end
  end
end
