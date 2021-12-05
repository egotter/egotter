require 'rails_helper'

RSpec.describe ApiClientCacheStore, type: :model do
  describe '.redis' do
    subject { described_class.redis }
    before do
      if described_class.instance_variable_defined?(:@redis)
        described_class.remove_instance_variable(:@redis)
      end
    end
    it do
      expect(Redis).to receive(:new).with(hash_including(db: 2))
      subject
    end
  end
end
