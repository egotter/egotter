require 'rails_helper'

RSpec.describe PersonalityInsight, type: :model do
  let(:insight) { described_class.new(profile: {personality: [], needs: [], values: []}) }

  describe '#personality_traits' do
    subject { insight.personality_traits }
    it { is_expected.to be_truthy }
  end

  describe '#needs_traits' do
    subject { insight.needs_traits }
    it { is_expected.to be_truthy }
  end

  describe '#values_traits' do
    subject { insight.values_traits }
    it { is_expected.to be_truthy }
  end

  describe '.fetch_profile' do
    subject { described_class.send(:fetch_profile, nil, nil) }
    before { allow(URI).to receive(:parse).with(anything).and_raise(Net::ReadTimeout) }
    it { expect { subject }.to raise_error(described_class::RetryExhausted) }
  end
end
