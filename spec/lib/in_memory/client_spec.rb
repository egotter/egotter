require 'rails_helper'

RSpec.describe InMemory::Client do
  let(:redis) { double('redis') }
  let(:instance) { described_class.new('klass', 'hostname') }
  let(:key) { 1 }

  before do
    instance.instance_variable_set(:@redis, redis)
  end

  describe '#ttl' do
    subject { instance.ttl }
    it { is_expected.to be_between(1.hour - 60, 1.hour + 60) }
  end

  describe '#read' do
    subject { instance.read(key) }
    before { allow(instance).to receive(:db_key).with(key).and_return('key') }

    it do
      expect(redis).to receive(:get).with('key').and_return('output')
      is_expected.to eq('output')
    end
  end

  describe '#write' do
    subject { instance.write(key, 'input') }
    before do
      allow(instance).to receive(:db_key).with(key).and_return('key')
      allow(instance).to receive(:ttl).and_return('ttl')
    end

    it do
      expect(redis).to receive(:setex).with('key', 'ttl', 'input')
      subject
    end
  end

  describe '#delete' do
    subject { instance.delete(key) }
    before { allow(instance).to receive(:db_key).with(key).and_return('key') }

    it do
      expect(redis).to receive(:del).with('key')
      subject
    end
  end

  describe '#db_key' do
    subject { instance.send(:db_key, 1) }
    it { is_expected.to eq('test:InMemory::Client:klass:1') }
  end

  context 'Invalid hostname is passed' do
    let(:redis) { Redis.client('invalid hostname') }

    [
        [:read, [1]],
        [:write, [1, 'data']],
        [:delete, [1]]
    ].each do |method_name, args|
      describe "##{method_name}" do
        subject { instance.send(method_name, *args) }
        it { expect { subject }.to raise_error(RuntimeError) }
      end
    end
  end
end
