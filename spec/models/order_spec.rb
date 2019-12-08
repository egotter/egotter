require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:user) { create(:user) }

  describe '#cancel!' do
    let(:order) { create(:order, user_id: user.id, subscription_id: 'sub', canceled_at: nil) }
    let(:canceled_at) { Time.zone.now }
    subject { order.cancel! }

    before do
      allow(Stripe::Subscription).to receive(:delete).with('sub').and_return(double('Stripe::Subscription', canceled_at: canceled_at))
    end

    it do
      subject
      expect(order.canceled_at).to be_present
    end
  end
end
