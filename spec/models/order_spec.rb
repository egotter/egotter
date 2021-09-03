require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id) }

  describe '.create_by_checkout_session' do
    let(:metadata) { double('metadata', price: 123) }
    let(:checkout_session) { double('checkout_session', id: 'cs_111', client_reference_id: user.id, customer_email: 'a@b.com', metadata: metadata, customer: 'cus_222', subscription: 'sub_333') }
    subject { described_class.create_by_checkout_session(checkout_session) }
    it { expect { subject }.to change { Order.all.size }.by(1) }
  end

  describe '.create_by_shop_item' do
    subject { described_class.create_by_shop_item(user, 'a@b.com', 'name', 0, 'cus_xxx', 'sub_xxx') }
    it { expect { subject }.to change { Order.all.size }.by(1) }
  end

  describe '.create_by_bank_transfer' do
    # TODO
  end

  describe '#cancel!' do
    let(:order) { create(:order, user_id: user.id, subscription_id: 'sub_111', canceled_at: nil) }
    let(:canceled_at) { Time.zone.at(Time.zone.now.to_i) }
    let(:subscription) { double('subscription', status: 'active') }
    let(:canceled_subscription) { double('subscription', status: 'canceled', canceled_at: canceled_at.to_i) }
    subject { order.cancel! }
    before do
      allow(Stripe::Subscription).to receive(:retrieve).with(order.subscription_id).and_return(subscription)
    end

    it do
      expect(Stripe::Subscription).to receive(:delete).with(order.subscription_id).and_return(canceled_subscription)
      subject
      order.reload
      expect(order.canceled_at).to eq(canceled_at)
    end

    context 'subscription has already been canceled' do
      before do
        allow(Stripe::Subscription).to receive(:retrieve).with(order.subscription_id).and_return(canceled_subscription)
      end

      it do
        expect(Stripe::Subscription).not_to receive(:delete)
        subject
        order.reload
        expect(order.canceled_at).to eq(canceled_at)
      end
    end
  end

  describe '#charge_succeeded!' do
    subject { order.charge_succeeded! }
    it { is_expected.to be_falsey }

    context '#charge_failed_at is present' do
      before { order.update(charge_failed_at: Time.zone.now) }
      it { is_expected.to be_truthy }
    end
  end

  describe '#charge_failed!' do
    subject { order.charge_failed! }
    it { is_expected.to be_truthy }
  end
end
