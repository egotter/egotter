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

    before do
      allow(described_class).to receive(:create_stripe_customer).with(user.id, user.email).and_return(stripe_customer)
      allow(described_class).to receive(:calculate_price).with(anything).and_return(123)
    end

    it do
      is_expected.to match(a_hash_including(customer: 'cus_xxx', metadata: {user_id: user.id, price: 123}))
    end

    context 'The user already has a customer_id' do
      before { allow(user).to receive(:valid_customer_id).and_return('cus_xxx') }
      it { expect(subject[:customer]).to eq('cus_xxx') }
    end

    context 'The user has a coupon_id' do
      before do
        allow(user).to receive(:valid_customer_id).and_return('cus_xxx')
        allow(user).to receive(:coupons_stripe_coupon_ids).and_return(['coupon_xxx'])
      end
      it { expect(subject[:discounts][0]).to eq(coupon: 'coupon_xxx') }
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
end
