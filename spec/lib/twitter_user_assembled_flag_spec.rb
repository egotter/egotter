require 'rails_helper'

RSpec.describe TwitterUserAssembledFlag, type: :model do
  let(:uid) { 1 }

  before { RedisClient.new.flushall }

  describe '.on' do
    it do
      expect(described_class.on?(uid)).to be_falsey
      described_class.on(uid)
      expect(described_class.on?(uid)).to be_truthy
    end
  end
end
