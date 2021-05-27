require 'rails_helper'

RSpec.describe StripeCheckoutSession, type: :model do
  let(:user) { create(:user) }

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

    before { allow(described_class).to receive(:calculate_price).with(anything).and_return(123) }

    it { expect(subject[:customer]).to be_nil }

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
end
