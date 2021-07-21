require 'rails_helper'

RSpec.describe ProcessStripePaymentIntentSucceededEventWorker do
  let(:worker) { described_class.new }
  let(:stripe_payment_intent_id) { 'pi_xxxx' }
  let(:user) { create(:user) }
  let(:payment_intent) { create(:payment_intent, user_id: user.id, stripe_payment_intent_id: stripe_payment_intent_id) }

  before do
    allow(worker).to receive(:send_message).with(anything)
  end

  describe '#perform' do
    let(:stripe_payment_intent) { double('stripe_payment_intent') }
    subject { worker.perform(stripe_payment_intent_id) }
    it do
      expect(Stripe::PaymentIntent).to receive(:retrieve).with(stripe_payment_intent_id).and_return(stripe_payment_intent)
      expect(StripePaymentIntent).to receive(:intent_for_bank_transfer?).with(stripe_payment_intent).and_return(true)
      expect(PaymentIntent).to receive(:find_by).with(stripe_payment_intent_id: stripe_payment_intent_id).and_return(payment_intent)
      expect(worker).to receive(:create_order).with(stripe_payment_intent, payment_intent)
      subject
    end
  end

  describe '#create_order' do
    # TODO
  end
end
