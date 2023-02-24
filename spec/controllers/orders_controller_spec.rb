require 'rails_helper'

RSpec.describe OrdersController, type: :controller do
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id) }

  describe 'GET #success' do
    context 'Checkout session is not passed' do
      subject { get :success }
      it { is_expected.to redirect_to(settings_order_history_path(via: 'orders/success/stripe_session_id_not_found')) }
    end

    context 'Checkout session is passed' do
      let(:checkout_session) { double('checkout session', id: 'cs_xxx', mode: nil, subscription: 'sub_xxx') }
      subject { get :success, params: {stripe_session_id: checkout_session.id} }
      before do
        allow(Stripe::Checkout::Session).to receive(:retrieve).with(checkout_session.id).and_return(checkout_session)
      end

      context 'mode is payment' do
        let(:checkout_session) { double('checkout session', id: 'cs_xxx', mode: 'payment', subscription: 'sub_xxx') }
        it do
          expect(Order).to receive(:where).with(checkout_session_id: 'cs_xxx').and_return([])
          subject
        end
      end

      context 'mode is not payment' do
        it do
          expect(Order).to receive(:where).with(subscription_id: 'sub_xxx').and_return([])
          subject
        end
      end

      context '1 order found' do
        before do
          create(:order, user_id: user.id, name: 'Test', customer_id: 'cus_xxx', subscription_id: checkout_session.subscription)
        end
        it { is_expected.to have_http_status(:ok) }
      end

      context '0 order found' do
        it { is_expected.to redirect_to(orders_failure_path(via: 'order_not_found', stripe_session_id: checkout_session.id)) }
      end

      context 'More than 2 orders found' do
        before do
          create(:order, user_id: user.id, name: 'Test1', customer_id: 'cus_xxx', subscription_id: checkout_session.subscription)
          create(:order, user_id: user.id, name: 'Test2', customer_id: 'cus_xxx', subscription_id: checkout_session.subscription)
        end
        it { is_expected.to redirect_to(orders_failure_path(via: 'too_many_orders', stripe_session_id: checkout_session.id)) }
      end

      context 'An exception is raised' do
        let(:error) { RuntimeError.new }
        before { allow(Stripe::Checkout::Session).to receive(:retrieve).and_raise(error) }
        it do
          expect(Airbag).to receive(:exception).with(error, stripe_session_id: checkout_session.id)
          is_expected.to redirect_to(orders_failure_path(via: 'internal_error', stripe_session_id: checkout_session.id))
        end
      end
    end
  end

  describe 'GET #failure' do
    subject { get :failure, params: {} }
    before { allow(controller).to receive(:current_user).and_return(user) }
    it do
      expect(controller).to receive(:send_message).with(:orders_failure, anything)
      is_expected.to have_http_status(:ok)
    end
  end

  describe 'GET #end_trial_failure' do
    subject { get :end_trial_failure, params: {} }
    before { allow(controller).to receive(:current_user).and_return(user) }
    it do
      expect(controller).to receive(:send_message).with(:orders_end_trial_failure)
      is_expected.to have_http_status(:ok)
    end
  end

  describe 'POST #checkout_session_completed' do
    subject { post :checkout_session_completed, params: {} }
    it do
      expect(controller).to receive(:construct_webhook_event).and_return('event')
      expect(controller).to receive(:process_webhook_event).with('event')
      is_expected.to have_http_status(:ok)
    end

    context 'An exception is raised' do
      let(:error) { RuntimeError.new }
      before { allow(controller).to receive(:construct_webhook_event).and_raise(error) }
      it do
        expect(Airbag).to receive(:exception).with(error)
        is_expected.to have_http_status(:bad_request)
      end
    end
  end

  describe '#construct_webhook_event' do
    let(:request) { double('request') }
    subject { controller.send(:construct_webhook_event) }
    before do
      allow(controller).to receive(:request).and_return(request)
      allow(request).to receive(:body).and_return(StringIO.new('payload'))
      allow(request).to receive(:headers).and_return({'HTTP_STRIPE_SIGNATURE' => 'signature'})
    end
    it do
      expect(Stripe::Webhook).to receive(:construct_event).with('payload', 'signature', ENV['STRIPE_ENDPOINT_SECRET'])
      subject
    end
  end

  describe '#process_webhook_event' do
    let(:event) { double('event', request: double('request', idempotency_key: 'key'), id: 'eid', type: type, data: double('event_data', object: {data: true})) }
    subject { controller.send(:process_webhook_event, event) }

    [
        ['checkout.session.completed', :process_checkout_session_completed],
        ['charge.succeeded', :process_charge_succeeded],
        ['charge.failed', :process_charge_failed],
        ['payment_intent.succeeded', :process_payment_intent_succeeded],
    ].each do |event_type, method_name|
      context "type is #{event_type}" do
        let(:type) { event_type }
        it do
          expect(controller).to receive(method_name).with(event)
          expect(controller).to receive(:create_stripe_webhook_log).with('key', 'eid', type, {data: true})
          subject
        end
      end
    end

    [
        ['other.event'],
    ].each do |event_type|
      context "type is #{event_type}" do
        let(:type) { event_type }
        it do
          expect(Airbag).to receive(:info).with('Unhandled stripe webhook event', event_id: 'eid', event_type: type)
          expect(controller).to receive(:create_stripe_webhook_log).with('key', 'eid', type, {data: true})
          subject
        end
      end
    end
  end

  describe '#process_checkout_session_completed' do
    let(:event) { double('event') }
    subject { controller.send(:process_checkout_session_completed, event) }
    before do
      allow(event).to receive_message_chain(:data, :object, :id).and_return('cs_xxxx')
    end
    it do
      expect(ProcessStripeCheckoutSessionCompletedEventWorker).to receive_message_chain(:new, :perform).with('cs_xxxx')
      subject
    end
  end

  describe '#process_charge_succeeded' do
    let(:event) { double('event') }
    subject { controller.send(:process_charge_succeeded, event) }
    before do
      allow(event).to receive_message_chain(:data, :object, :customer).and_return('cus_xxxx')
    end
    it do
      expect(ProcessStripeChargeSucceededEventWorker).to receive(:perform_in).with(5, 'cus_xxxx')
      subject
    end
  end

  describe '#process_charge_failed' do
    let(:event) { double('event', id: 'eid') }
    let(:charge) { double('charge', id: 'cid', customer: 'cus_xxx') }
    subject { controller.send(:process_charge_failed, event) }
    before { allow(event).to receive_message_chain(:data, :object).and_return(charge) }
    it do
      expect(ProcessStripeChargeFailedEventWorker).to receive(:perform_async).with('cus_xxx', event_id: event.id, charge_id: charge.id)
      subject
    end
  end

  describe '#process_payment_intent_succeeded' do
    let(:event) { double('event') }
    subject { controller.send(:process_payment_intent_succeeded, event) }
    before do
      allow(event).to receive_message_chain(:data, :object, :id).and_return('pi_xxxx')
    end
    it do
      expect(ProcessStripePaymentIntentSucceededEventWorker).to receive(:perform_async).with('pi_xxxx')
      subject
    end
  end

  describe '#send_message' do
    subject { controller.send(:send_message, 'channel', opt: true) }
    before { allow(controller).to receive(:params).and_return(via: 'via') }

    context 'The user is signed in' do
      before do
        allow(controller).to receive(:user_signed_in?).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end
      it do
        expect(SendMessageToSlackWorker).to receive(:perform_async).with('channel', instance_of(String))
        subject
      end
    end

    context 'The user is NOT signed in' do
      before do
        allow(controller).to receive(:user_signed_in?).and_return(false)
      end
      it do
        expect(SendMessageToSlackWorker).to receive(:perform_async).with('channel', instance_of(String))
        subject
      end
    end

    context 'An exception is raised' do
      let(:error) { RuntimeError.new }
      before { allow(controller).to receive(:user_signed_in?).and_raise(error) }
      it do
        expect(Airbag).to receive(:exception).with(error, channel: 'channel', options: {opt: true})
        subject
      end
    end
  end
end
