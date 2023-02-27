require 'rails_helper'

RSpec.describe CheckoutSessionBuilder, type: :model do
  let(:user) { create(:user, email: 'a@b.com') }
  let(:stripe_customer) { double('stripe customer', id: 'cus_xxx') }

  describe '.monthly_subscription' do
    subject { described_class.monthly_subscription(user) }

    before do
      allow(described_class).to receive(:find_or_create_customer).with(user).and_return('cus_xxx')
      allow(described_class).to receive(:apply_trial_days?).with(user).and_return(true)
      allow(described_class).to receive(:available_discounts).with(user).and_return('discount')
      expect(described_class).to receive(:calculate_price).with(anything).and_return(123)
    end

    it do
      is_expected.to eq(client_reference_id: user.id,
                        mode: 'subscription',
                        line_items: [{quantity: 1, price: Order::BASIC_PLAN_PRICE_ID}],
                        subscription_data: {default_tax_rates: [Order::TAX_RATE_ID], trial_period_days: Order::TRIAL_DAYS},
                        metadata: {user_id: user.id, price: 123, item_id: 'subscription'},
                        success_url: ENV['STRIPE_SUCCESS_URL'],
                        cancel_url: ENV['STRIPE_CANCEL_URL'],
                        expires_at: 30.minutes.since.to_i,
                        customer: 'cus_xxx',
                        discounts: 'discount')
    end
  end

  describe '.monthly_basis' do
    let(:item_id) { 'monthly-basis-1' }
    let(:price) { Order::BASIC_PLAN_MONTHLY_BASIS[item_id] }
    let(:name) { I18n.t('stripe.monthly_basis.name', count: 1) }
    let(:item) {
      {
          price_data: {
              currency: 'jpy',
              product_data: {name: name, description: I18n.t('stripe.monthly_basis.description')},
              unit_amount: price,
          },
          tax_rates: [Order::TAX_RATE_ID],
          quantity: 1,
      }
    }
    subject { described_class.monthly_basis(user, item_id) }

    before do
      allow(described_class).to receive(:find_or_create_customer).with(user).and_return('cus_xxx')
    end

    it do
      is_expected.to eq(client_reference_id: user.id,
                        payment_method_types: ['card'],
                        mode: 'payment',
                        line_items: [item],
                        metadata: {user_id: user.id, name: name, price: price, months_count: '1', item_id: item_id},
                        success_url: ENV['STRIPE_SUCCESS_URL'],
                        cancel_url: ENV['STRIPE_CANCEL_URL'],
                        expires_at: 30.minutes.since.to_i,
                        customer: 'cus_xxx',
                     )
    end
  end

  describe '.find_or_create_customer' do
    subject { described_class.send(:find_or_create_customer, user) }

    context 'User has a customer_id' do
      before { create(:customer, user_id: user.id, stripe_customer_id: 'cus_xxx') }
      it { is_expected.to eq('cus_xxx') }
    end

    context "User doesn't a customer_id" do
      let(:stripe_customer) { double('stripe customer', id: 'cus_xxx') }
      it do
        expect(described_class).to receive(:create_stripe_customer).with(user.id, user.email).and_return(stripe_customer)
        is_expected.to eq('cus_xxx')
      end
    end
  end

  describe '.create_stripe_customer' do
    let(:customer_options) { {email: user.email, metadata: {user_id: user.id}} }
    subject { described_class.send(:create_stripe_customer, user.id, user.email) }

    before do
      allow(Stripe::Customer).to receive(:create).with(customer_options).and_return(stripe_customer)
    end

    it { is_expected.to eq(stripe_customer) }

    context 'email is nil' do
      let(:customer_options) { {metadata: {user_id: user.id}} }
      before { user.email = nil }
      it { is_expected.to eq(stripe_customer) }
    end

    context 'email is blank' do
      let(:customer_options) { {metadata: {user_id: user.id}} }
      before { user.email = '' }
      it { is_expected.to eq(stripe_customer) }
    end

    context 'email is invalid' do
      let(:customer_options) { {metadata: {user_id: user.id}} }
      before { user.email = 'abc' }
      it { is_expected.to eq(stripe_customer) }
    end
  end

  describe '.available_discounts' do
    subject { described_class.send(:available_discounts, user) }

    context 'User has an order' do
      before { create(:order, user_id: user.id) }

      context 'User has a coupon' do
        before { allow(user).to receive(:coupons_stripe_coupon_ids).and_return(['coupon_id']) }
        it { is_expected.to eq([{coupon: 'coupon_id'}]) }
      end

      context "User doesn't have any coupon" do
        it { is_expected.to be_empty }
      end
    end

    context "User doesn't have any order" do
      before { allow(user).to receive(:orders).and_return([]) }
      it { is_expected.to eq([{coupon: Order::COUPON_ID}]) }
    end
  end
end
