require 'rails_helper'

RSpec.describe DirectMessageSendCounter, type: :model do
  let(:uid) { 1 }

  before { RedisClient.new.flushall }

  describe '.increment' do
    it do
      expect(described_class.sent_count(uid)).to eq(0)
      described_class.increment(uid)
      expect(described_class.sent_count(uid)).to eq(1)
      expect(described_class.ttl(uid)).to be_between(1.day - 10.seconds, 1.day + 10.seconds)
    end
  end

  describe '.messages_left?' do
    it do
      expect(described_class.messages_left?(uid)).to be_truthy
      4.times { described_class.increment(uid) }
      expect(described_class.messages_left?(uid)).to be_truthy
      described_class.increment(uid)
      expect(described_class.messages_left?(uid)).to be_falsey
    end
  end
end
