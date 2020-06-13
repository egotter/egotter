require 'rails_helper'

RSpec.describe SendMetricsToCloudWatchWorker do
  let(:worker) { described_class.new }

  describe '#send_periodic_reports_metrics' do
    let(:user) { create(:user) }
    subject { worker.send(:send_periodic_reports_metrics) }
    before do
      PeriodicReport.create!(user_id: user.id, token: PeriodicReport.generate_token, message_id: 1, read_at: Time.zone.now)
    end
    it do
      expect(worker).to receive(:put_metric_data).with(any_args).exactly(9).times
      subject
    end
  end

  describe '#send_create_periodic_report_requests_metrics' do
    let(:user) { create(:user) }
    subject { worker.send(:send_create_periodic_report_requests_metrics) }
    before do
      CreatePeriodicReportRequest.create!(user_id: user.id, status: 'test')
    end
    it do
      expect(worker).to receive(:put_metric_data).with(any_args).exactly(3).times
      subject
    end
  end
end
