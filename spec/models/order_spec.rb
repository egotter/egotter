require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id) }

  describe '.create_by_checkout_session' do
    let(:metadata) { double('metadata', price: 123) }
    let(:checkout_session) { double('checkout_session', id: 'cs_111', client_reference_id: user.id, metadata: metadata, customer: 'cus_222', subscription: 'sub_333') }
    subject { described_class.create_by_checkout_session(checkout_session) }
    it { expect { subject }.to change { Order.all.size }.by(1) }
  end

  describe '.create_by_monthly_basis' do
    let(:metadata) { double('metadata', name: 'test plan', price: 123, months_count: 1, item_id: 'monthly-basis-1') }
    let(:customer_details) { double('customer_details', email: nil) }
    let(:checkout_session) { double('checkout_session', id: 'cs_111', client_reference_id: user.id, customer_details: customer_details, metadata: metadata, customer: 'cus_222') }
    let(:subscription) { double('subscription', id: 'sub_xxx') }
    subject { described_class.create_by_monthly_basis(checkout_session) }
    it do
      expect(Stripe::Subscription).to receive(:create).with(
          customer: 'cus_222',
          items: [{price: Order::BASIC_PLAN_MONTHLY_BASIS_PRICE_IDS['monthly-basis-1']}],
          metadata: {user_id: user.id, price: 0, months_count: 1, item_id: 'monthly-basis-1'}
      ).and_return(subscription)
      expect { subject }.to change { Order.all.size }.by(1)
    end
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
    subject { order.cancel!('test') }
    before do
      allow(Stripe::Subscription).to receive(:retrieve).with(order.subscription_id).and_return(subscription)
    end

    it do
      expect(Stripe::Subscription).to receive(:cancel).with(order.subscription_id).and_return(canceled_subscription)
      expect(order).to receive(:update!).with(cancel_source: 'test', canceled_at: instance_of(ActiveSupport::TimeWithZone)).and_call_original
      subject
      order.reload
      expect(order.cancel_source).to eq('test')
      expect(order.canceled_at).to eq(canceled_at)
    end

    context 'subscription has already been canceled' do
      before do
        allow(Stripe::Subscription).to receive(:retrieve).with(order.subscription_id).and_return(canceled_subscription)
      end

      it do
        expect(SendMessageToSlackWorker).to receive(:perform_async).with(:orders_warning, instance_of(String))
        expect(Stripe::Subscription).not_to receive(:cancel)
        expect(order).to receive(:update!).with(cancel_source: 'test', canceled_at: instance_of(ActiveSupport::TimeWithZone)).and_call_original
        subject
        order.reload
        expect(order.cancel_source).to eq('test')
        expect(order.canceled_at).to eq(canceled_at)
      end
    end

    context 'Stripe::InvalidRequestError is raised' do
      let(:error) { Stripe::InvalidRequestError.new('No such subscription', nil) }
      before do
        allow(Stripe::Subscription).to receive(:retrieve).with(anything).and_raise(error)
      end

      it do
        expect(SendMessageToSlackWorker).to receive(:perform_async).with(:orders_warning, instance_of(String))
        expect(order).to receive(:update!).with(cancel_source: 'test', canceled_at: instance_of(ActiveSupport::TimeWithZone)).and_call_original
        subject
        order.reload
        expect(order.cancel_source).to eq('test')
        expect(order.canceled_at).to eq(canceled_at)
      end
    end
  end
end
