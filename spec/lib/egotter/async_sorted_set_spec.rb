require 'rails_helper'

RSpec.describe Egotter::AsyncSortedSet do
  let(:instance) { described_class.new(Redis.client) }
  let(:default_ttl) { 60 }

  before do
    Redis.client.flushdb
    instance.instance_variable_set(:@key, 'key')
    instance.instance_variable_set(:@ttl, default_ttl)
  end

  describe 'cleanup' do
    subject { instance.cleanup }

    context '@async_flag is true' do
      before { instance.instance_variable_set(:@async_flag, true) }
      it do
        expect(SortedSetCleanupWorker).to receive(:perform_async).with(described_class)
        subject
      end
    end

    context '@async_flag is false' do
      before { instance.instance_variable_set(:@async_flag, false) }
      it do
        expect(instance.redis).to receive(:zremrangebyscore).with(any_args)
        subject
      end
    end
  end
end
