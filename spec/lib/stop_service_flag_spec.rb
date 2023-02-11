require 'rails_helper'

RSpec.describe StopServiceFlag, type: :model do
  before { RedisClient.new.flushall }

  describe '.on' do
    let(:id) { 'visitor_token' }
    it do
      expect(described_class.on?).to be_falsey
      described_class.on
      expect(described_class.on?).to be_truthy
      described_class.off
      expect(described_class.on?).to be_falsey
    end
  end
end
