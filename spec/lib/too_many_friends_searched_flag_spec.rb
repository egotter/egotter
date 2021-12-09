require 'rails_helper'

RSpec.describe TooManyFriendsSearchedFlag, type: :model do
  let(:user_id) { 1 }

  before { RedisClient.new.flushall }

  describe '.on' do
    it do
      expect(described_class.on?(user_id)).to be_falsey
      described_class.on(user_id)
      expect(described_class.on?(user_id)).to be_truthy
    end
  end
end
