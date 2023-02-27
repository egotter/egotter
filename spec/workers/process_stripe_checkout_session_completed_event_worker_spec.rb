require 'rails_helper'

RSpec.describe ProcessStripeCheckoutSessionCompletedEventWorker do
  let(:worker) { described_class.new }
  let(:checkout_session_id) { 'cs_xxx' }
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id) }

  describe '#perform' do
    let(:checkout_session) { double('checkout_session', mode: nil, client_reference_id: user.id) }
    subject { worker.perform(checkout_session_id) }

    before do
      allow(Stripe::Checkout::Session).to receive(:retrieve).with(checkout_session_id).and_return(checkout_session)
    end

    context 'A user is not found' do
      before { allow(User).to receive(:find_by).with(id: user.id).and_return(nil) }
      it do
        expect(worker).to receive(:send_error_message).with('[To Be Fixed] User not found', any_args)
        subject
      end
    end

    context 'The user already has a subscription' do
      before do
        allow(User).to receive(:find_by).with(id: user.id).and_return(user)
        allow(user).to receive(:has_valid_subscription?).and_return(true)
      end
      it do
        allow(worker).to receive(:send_error_message).with('[To Be Fixed] User already has a subscription', any_args)
        subject
      end
    end

    context 'A user that does not have a subscription is found' do
      before do
        allow(User).to receive(:find_by).with(id: user.id).and_return(user)
        allow(user).to receive(:has_valid_subscription?).and_return(false)
      end

      context 'mode is payment' do
        let(:checkout_session) { double('checkout_session', mode: 'payment', client_reference_id: user.id) }
        it do
          expect(Order).to receive(:create_by_monthly_basis).with(checkout_session).and_return(order)
          expect(worker).to receive(:update_trial_end_and_email).with(order)
          expect(worker).to receive(:send_message).with('Success', any_args)
          subject
        end
      end

      context 'mode is not payment' do
        it do
          expect(Order).to receive(:create_by_checkout_session).with(checkout_session).and_return(order)
          expect(worker).to receive(:update_trial_end_and_email).with(order)
          expect(worker).to receive(:send_message).with('Success', any_args)
          subject
        end
      end
    end

    context 'An error is raised' do
      let(:error) { RuntimeError.new }
      before do
        allow(Stripe::Checkout::Session).to receive(:retrieve).with(checkout_session_id).and_raise(error)
      end
      it do
        expect(Airbag).to receive(:exception).with(error, checkout_session_id: checkout_session_id)
        expect(worker).to receive(:send_error_message).with('[To Be Fixed] A fatal error occurred', checkout_session_id)
        subject
      end
    end
  end

  describe '#send_message' do
    subject { worker.send(:send_message, 'msg', 'cs_xxx', {props: true}) }
    it do
      expect(SendOrderMessageToSlackWorker).to receive(:perform_async).with(:orders_cs_completed, /msg/)
      subject
    end
  end

  describe '#send_error_message' do
    subject { worker.send(:send_error_message, 'msg', 'cs_xxx', {props: true}) }
    it do
      expect(worker).to receive(:send_message).with('msg', 'cs_xxx', {props: true})
      expect(SendOrderMessageToSlackWorker).to receive(:perform_async).with(:orders_warning, /msg/)
      subject
    end
  end
end
