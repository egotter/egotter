require 'rails_helper'

RSpec.describe Redis do
  describe '.client' do
    it do
      expect(described_class).to receive(:new).with(host: described_class::HOST, db: 1, timeout: 3.0, driver: :hiredis)
      Redis.client
    end

    context 'hostname is passed' do
      it do
        expect(described_class).to receive(:new).with(host: 'hostname', db: 1, timeout: 3.0, driver: :hiredis)
        Redis.client('hostname')
      end
    end

    context 'passed hostname is nil' do
      it do
        expect(described_class).to receive(:new).with(host: described_class::HOST, db: 1, timeout: 3.0, driver: :hiredis)
        Redis.client(nil)
      end
    end
  end

  describe '#fetch' do
    let(:client) { Redis.client }
    before { client.flushdb }
    it do
      expect(client.fetch('key')).to be_nil
      client.set('key', 'data')
      expect(client.fetch('key')).to eq('data')
    end
  end
end
