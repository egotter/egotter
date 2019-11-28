require 'rails_helper'

RSpec.describe EnqueuedSearchRequest do
  describe '#ttl' do
    let(:queue) { described_class.new }
    it do
      expect(queue.ttl).to be < TwitterUser::CREATE_RECORD_INTERVAL
    end
  end

  describe '#exists?' do
    let!(:queue) { described_class.new }
    let(:val) { 123 }
    subject { queue.exists?(val) }

    before do
      Redis.client.flushdb
      queue.add(val)
    end

    it do
      expect(queue.size).to eq(1)
    end

    context 'Before the expiration time' do
      it do
        travel(queue.ttl.seconds - 1.minute) do
          is_expected.to be_truthy
        end
      end
    end

    context 'After the expiration time' do
      it do
        travel(queue.ttl.seconds + 1.minute) do
          is_expected.to be_falsey
        end
      end
    end
  end
end
