require 'rails_helper'

RSpec.describe InMemory::Client do
  let(:redis) { double('redis') }
  let(:instance) { described_class.new(redis, 'namespace') }
  let(:key) { 1 }

  describe '#read' do
    subject { instance.read(key) }
    before { allow(instance).to receive(:db_key).with(key).and_return('key') }

    it do
      expect(redis).to receive(:get).with('key').and_return('output')
      is_expected.to eq('output')
    end

    context 'Redis::TimeoutError is raised' do
      before { allow(redis).to receive(:get).with(anything).and_raise(Redis::TimeoutError) }
      it do
        expect { subject }.to raise_error(Redis::TimeoutError)
        expect(instance.instance_variable_get(:@retries)).to eq(4)
      end
    end

    context 'RuntimeError is raised' do
      before { allow(redis).to receive(:get).with(anything).and_raise(RuntimeError) }
      it do
        expect { subject }.to raise_error(RuntimeError)
        expect(instance.instance_variable_get(:@retries)).to eq(0)
      end
    end
  end

  describe '#write' do
    subject { instance.write(key, 'input') }
    before do
      allow(instance).to receive(:db_key).with(key).and_return('key')
    end

    it do
      expect(redis).to receive(:setex).with('key', instance_of(Integer), 'input')
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
    it { is_expected.to eq('test:InMemory::Client:namespace:1') }
  end

  context 'Invalid hostname is passed' do
    # TODO If you don't specify a timeout, sometimes it might take a long time.
    let(:redis) { Redis.client('invalid hostname', connect_timeout: 0.1) }

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
