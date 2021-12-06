require 'rails_helper'

RSpec.describe DirectMessageLimitedFlag, type: :model do
  before { RedisClient.new.flushall }

  describe '.on' do
    it do
      expect(described_class.on?).to be_falsey
      described_class.on
      expect(described_class.on?).to be_truthy
    end
  end

  describe '.remaining' do
    it do
      described_class.on
      expect(described_class.remaining > 0).to be_truthy
    end
  end
end
