require 'rails_helper'

RSpec.describe TimelineReadableFlag, type: :model do
  let(:user_id) { 1 }
  let(:uid) { 2 }

  before { RedisClient.new.flushall }

  describe '.on' do
    it do
      expect(described_class.on?(user_id, uid)).to be_falsey
      expect(described_class.off?(user_id, uid)).to be_falsey
      described_class.on(user_id, uid)
      expect(described_class.on?(user_id, uid)).to be_truthy
      expect(described_class.off?(user_id, uid)).to be_falsey
    end
  end

  describe '.off' do
    it do
      expect(described_class.on?(user_id, uid)).to be_falsey
      expect(described_class.off?(user_id, uid)).to be_falsey
      described_class.off(user_id, uid)
      expect(described_class.on?(user_id, uid)).to be_falsey
      expect(described_class.off?(user_id, uid)).to be_truthy
    end
  end

  describe '.clear' do
    it do
      expect(described_class.on?(user_id, uid)).to be_falsey
      expect(described_class.off?(user_id, uid)).to be_falsey

      described_class.on(user_id, uid)
      expect(described_class.on?(user_id, uid)).to be_truthy
      expect(described_class.off?(user_id, uid)).to be_falsey

      described_class.clear(user_id, uid)
      expect(described_class.on?(user_id, uid)).to be_falsey
      expect(described_class.off?(user_id, uid)).to be_falsey
    end
  end
end
