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
        send_twitter_db_users_metrics
        send_search_histories_metrics
        send_sign_in_logs_metrics
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
