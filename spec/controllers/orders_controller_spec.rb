require 'rails_helper'

RSpec.describe OrdersController, type: :controller do
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id) }

  describe 'POST #checkout_session_completed' do
    subject { post :checkout_session_completed, params: {} }
    it do
      expect(controller).to receive(:construct_webhook_event).and_return('event')
      expect(controller).to receive(:process_webhook_event).with('event')
      is_expected.to have_http_status(:ok)
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
    let(:event) { double('event', type: type) }
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
      expect(ProcessStripeCheckoutSessionCompletedEventWorker).to receive(:perform_async).with('cs_xxxx')
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
      expect(ProcessStripeChargeSucceededEventWorker).to receive(:perform_async).with('cus_xxxx')
      subject
    end
  end

  describe '#process_charge_failed' do
    let(:event) { double('event') }
    subject { controller.send(:process_charge_failed, event) }
    before do
      allow(event).to receive_message_chain(:data, :object, :customer).and_return('cus_xxxx')
    end
    it do
      expect(ProcessStripeChargeFailedEventWorker).to receive(:perform_async).with('cus_xxxx')
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
end
