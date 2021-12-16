require 'rails_helper'

RSpec.describe SendMetricsToCloudWatchWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform }
    it do
      %i(
        send_google_analytics_metrics
    ).each do |method_name|
        expect(worker).to receive(method_name)
      end
      subject
    end
  end
end

RSpec.describe SendMetricsToCloudWatchWorker::Metrics, type: :model do
  describe '#append' do
    let(:instance) { described_class.new }
    let(:namespace) { 'namespace' }
    let(:name) { 'name' }
    let(:dimensions) { 'dimensions' }
    let(:value) { 'value' }
    let(:send_data) do
      {
          metric_name: name,
          dimensions: dimensions,
          timestamp: Time.zone.now,
          value: value,
          unit: 'Count'
      }
    end
    subject { instance.append(name, value, namespace: namespace, dimensions: dimensions) }

    it do
      freeze_time do
        subject
        expect(instance.instance_variable_get(:@metrics)).to match({namespace => [send_data]})
        expect(instance.instance_variable_get(:@appended)).to be_truthy
      end
    end
  end

  describe '#update' do
    let(:instance) { described_class.new }
    let(:cw_client) { double('cw_client') }
    subject { instance.update }

    before do
      allow(Aws::CloudWatch::Client).to receive(:new).with(region: CloudWatchClient::REGION).and_return(cw_client)
      instance.instance_variable_set(:@appended, true)
      instance.instance_variable_set(:@metrics, {'namespace' => [{'key' => 'value'}]})
    end

    it do
      expect(cw_client).to receive(:put_metric_data).with({namespace: 'namespace', metric_data: [{'key' => 'value'}]})
      subject
    end
  end
end
