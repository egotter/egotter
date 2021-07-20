require 'rails_helper'

RSpec.describe PaymentIntent, type: :model do
  let(:user) { create(:user) }

  describe '.accepting_bank_transfer' do
    subject { described_class.accepting_bank_transfer(user) }
    before do
      [nil, Time.zone.now].repeated_permutation(2) do |t1, t2|
        create(:payment_intent, user_id: user.id, expiry_date: 1.day.since, succeeded_at: t1, canceled_at: t2)
      end
    end
    it { expect(subject.size).to eq(1) }
  end
end
