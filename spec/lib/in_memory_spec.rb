require 'rails_helper'

RSpec.describe InMemory do
  describe '.enabled?' do
    it { expect(described_class.enabled?).to be_truthy }
  end

  describe '#ttl_with_random' do
    subject { described_class.ttl_with_random }
    it { is_expected.to be_between(1.hour - 60, 1.hour + 60) }
  end

  describe '.cache_alive?' do
    subject { described_class.cache_alive?(time) }

    context 'The time is a short time ago' do
      let(:time) { 1.second.ago }
      it { is_expected.to be_truthy }
    end

    context 'The time is a long time ago' do
      let(:time) { 1.year.ago }
      it { is_expected.to be_falsey }
    end
  end
end
