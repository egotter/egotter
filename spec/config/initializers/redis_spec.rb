require 'rails_helper'

RSpec.describe Redis do
  let(:options) do
    {host: host, db: 1, connect_timeout: 1.5, read_timeout: 1.0, write_timeout: 0.5, driver: :hiredis}
  end

  describe '.client' do
    let(:host) { described_class::HOST }
    it do
      expect(described_class).to receive(:new).with(options)
      Redis.client
    end

    context 'hostname is passed' do
      let(:host) { 'hostname' }
      it do
        expect(described_class).to receive(:new).with(options)
        Redis.client('hostname')
      end
    end

    context 'passed hostname is nil' do
      let(:host) { described_class::HOST }
      it do
        expect(described_class).to receive(:new).with(options)
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
