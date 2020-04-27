require 'rails_helper'

RSpec.describe Efs::Client do
  let(:efs) { double('efs') }
  let(:instance) { described_class.new('key_prefix', 'klass') }
  let(:key) { 1 }

  before do
    instance.instance_variable_set(:@efs, efs)
    allow(instance).to receive(:cache_key).with(key).and_return('key')
  end

  describe '#read' do
    subject { instance.read(key) }

    it do
      expect(efs).to receive(:read).with('key').and_return('output')
      is_expected.to eq('output')
    end
  end

  describe '#write' do
    subject { instance.write(key, 'input') }

    it do
      expect(DeleteFromEfsWorker).to receive(:perform_in).with(1.hour, klass: 'klass', key: key)
      expect(efs).to receive(:write).with('key', 'input')
      subject
    end
  end

  describe '#delete' do
    subject { instance.delete(key) }

    it do
      expect(efs).to receive(:delete).with('key')
      subject
    end
  end
end
