require 'rails_helper'

RSpec.describe StripePaymentIntent, type: :model do
  let(:user) { create(:user) }

  if ENV['STRIPE_TEST']
    describe '.intent_for_bank_transfer?' do
      let(:intent) { described_class.create(user) }
      subject { described_class.intent_for_bank_transfer?(intent) }
      it { is_expected.to be_truthy }
    end
  end
end
