require 'rails_helper'

RSpec.describe SendMetricsToCloudWatchWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform }
    it do
      %i(
        send_google_analytics_metrics
        send_periodic_reports_metrics
        send_create_periodic_report_requests_metrics
        send_search_error_logs_metrics
        send_search_histories_metrics
        send_requests_metrics
        send_bots_metrics
    ).each do |method_name|
        expect(worker).to receive(method_name)
      end
      subject
    end
  end

  describe '#send_periodic_reports_metrics' do
    let(:user) { create(:user) }
    subject { worker.send(:send_periodic_reports_metrics) }
    before do
      PeriodicReport.create!(user_id: user.id, token: PeriodicReport.generate_token, message_id: 1, read_at: Time.zone.now)
    end
    it do
      expect(worker).to receive(:put_metric_data).with(any_args).exactly(3).times
      subject
    end
  end

  describe '#send_create_periodic_report_requests_metrics' do
    let(:user) { create(:user) }
    subject { worker.send(:send_create_periodic_report_requests_metrics) }
    before do
      CreatePeriodicReportRequest.create!(user_id: user.id, status: 'test1')
      CreatePeriodicReportRequest.create!(user_id: user.id, status: 'test2')
      CreatePeriodicReportRequest.create!(user_id: user.id, status: '')
    end
    it do
      expect(worker).to receive(:put_metric_data).with(any_args).exactly(2).times
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
    let(:cw_client) { Aws::CloudWatch::Client.new(region: CloudWatchClient::REGION) }

    before do
      allow(Aws::CloudWatch::Client).to receive(:new).with(region: CloudWatchClient::REGION)
      instance.instance_variable_set(:@appended, true)
      instance.instance_variable_set(:@metrics, {'namespace' => [{'key' => 'value'}]})
    end

    it do
      expect(cw_client).to receive(:put_metric_data).with({namespace: 'namespace', metric_data: [{'key' => 'value'}]})
      instance.update
    end
  end

  describe '#logger' do
    it { expect(described_class.new.respond_to?(:logger)).to be_truthy }
  end
end
