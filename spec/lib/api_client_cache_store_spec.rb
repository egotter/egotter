require 'rails_helper'

RSpec.describe ApiClientCacheStore, type: :model do
  describe '.redis_client' do
    subject { described_class.redis_client }
    before do
      if described_class.instance_variable_defined?(:@redis_client)
        described_class.remove_instance_variable(:@redis_client)
      end
    end
    it do
      expect(Redis).to receive(:new).with(hash_including(db: 2))
      subject
    end
  end
end
