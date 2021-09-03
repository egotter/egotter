require 'rails_helper'

RSpec.describe StripeCheckoutSession, type: :model do
  let(:user) { create(:user, email: 'a@b.com') }
  let(:stripe_customer) { double('stripe customer', id: 'cus_xxx') }

  describe '.create' do
    subject { described_class.create(user) }

    it do
      expect(described_class).to receive(:build).with(user).and_return('attrs')
      expect(Stripe::Checkout::Session).to receive(:create).with('attrs')
      subject
    end
  end

  describe '.build' do
    subject { described_class.send(:build, user) }

    it do
      expect(described_class).to receive(:find_or_create_customer).with(user).and_return('cus_xxx')
      expect(described_class).to receive(:apply_trial_days?).with(user).and_return(true)
      expect(described_class).to receive(:available_discounts).with(user).and_return('discount')
      expect(described_class).to receive(:calculate_price).with(anything).and_return(123)
      is_expected.to match(a_hash_including(
                               customer: 'cus_xxx',
                               subscription_data: {trial_period_days: Order::TRIAL_DAYS, default_tax_rates: [Order::TAX_RATE_ID]},
                               metadata: {user_id: user.id, price: 123})
                     )
    end
  end

  describe '.find_or_create_customer' do
    subject { described_class.send(:find_or_create_customer, user) }

    context 'User has a customer_id' do
      before { allow(user).to receive(:valid_customer_id).and_return('cus_xxx') }
      it { is_expected.to eq('cus_xxx') }
    end

    context "User doesn't a customer_id" do
      let(:stripe_customer) { double('stripe customer', id: 'cus_xxx') }
      before { allow(user).to receive(:valid_customer_id).and_return(nil) }
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
