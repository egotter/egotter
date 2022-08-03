require 'rails_helper'

RSpec.describe WorkMeasurement do
  class TestWorkMeasurement
    prepend WorkMeasurement

    def timeout_in
      1
    end

    def perform(a)
      'result'
    end
  end

  class TestWorkMeasurementWithCallback < TestWorkMeasurement
    def after_timeout(*) end
  end

  describe '#measure_time' do
    let(:instance) { TestWorkMeasurement.new }
    subject { instance.measure_time('a') }
    before do
      instance.instance_variable_set(:@start, Time.zone.now)
      allow(instance).to receive(:timeout?).with(1).and_return(true)
    end

    it do
      expect(Airbag).to receive(:warn).with(instance_of(String), anything)
      expect(CreateSidekiqLogWorker).to receive(:perform_async).with(nil, 'WorkMeasurement', any_args)
      subject
    end

    context 'worker implements #after_timeout' do
      let(:instance) { TestWorkMeasurementWithCallback.new }
      it do
        expect(instance).to receive(:after_timeout).with('a')
        subject
      end
    end
  end

  describe '#perform' do
    let(:instance) { TestWorkMeasurement.new }
    subject { instance.perform('a') }
    it do
      expect(instance).to receive(:measure_time).with('a')
      is_expected.to eq('result')
    end
  end
end
