require 'rails_helper'

RSpec.describe TimeoutableWorker do
  class TestTimeoutableWorker
    prepend TimeoutableWorker

    def timeout_in
      1
    end

    def perform(a)
      'result'
    end
  end

  class TestTimeoutableWorkerWithCallback < TestTimeoutableWorker
    def after_timeout(*) end
  end

  describe '#measure_time' do
    let(:instance) { TestTimeoutableWorker.new }
    subject { instance.measure_time('a') }
    before { allow(instance).to receive(:timeout?).with(1).and_return(true) }

    it do
      expect(Airbag).to receive(:warn).with(instance_of(String), anything)
      subject
    end

    context 'worker implements #after_timeout' do
      let(:instance) { TestTimeoutableWorkerWithCallback.new }
      it do
        expect(instance).to receive(:after_timeout).with('a')
        subject
      end
    end
  end

  describe '#perform' do
    let(:instance) { TestTimeoutableWorker.new }
    subject { instance.perform('a') }
    it do
      expect(instance).to receive(:measure_time).with('a')
      is_expected.to eq('result')
    end
  end
end
