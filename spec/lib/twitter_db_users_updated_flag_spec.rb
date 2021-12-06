require 'rails_helper'

RSpec.describe TwitterDBUsersUpdatedFlag, type: :model do
  let(:uids) { [1, 2, 3] }

  before { RedisClient.new.flushall }

  describe '.on' do
    it do
      expect(described_class.on?(uids)).to be_falsey
      described_class.on(uids)
      expect(described_class.on?(uids)).to be_truthy
    end
  end
end
