require 'rails_helper'

RSpec.describe LoginCounter, type: :model do
  before { RedisClient.new.flushall }

  describe '.value' do
    let(:id) { 'visitor_token' }
    it do
      expect(described_class.value(id)).to eq(0)
      described_class.increment(id)
      expect(described_class.value(id)).to eq(1)
    end
  end
end
