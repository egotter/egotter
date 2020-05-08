require 'rails_helper'

RSpec.describe InMemory::Client do
  let(:redis) { double('redis') }
  let(:instance) { described_class.new('klass', 'hostname') }
  let(:key) { 1 }

  before do
    instance.instance_variable_set(:@redis, redis)
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
    before { allow(instance).to receive(:db_key).with(key).and_return('key') }

    it do
      expect(redis).to receive(:setex).with('key', 5.minutes, 'input')
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
        it "returns nil" do
          is_expected.to be_nil
        end

        it "doesn't raise an exception" do
          expect { subject }.not_to raise_error
        end
      end
    end
  end
end
