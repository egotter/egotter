require 'rails_helper'

RSpec.describe CreatePeriodicReportWorker do
  let(:user) { create(:user) }
  let(:request) { create(:create_periodic_report_request, user: user) }
  let(:worker) { described_class.new }

  before do
    allow(CreatePeriodicReportRequest).to receive(:find).with(request.id).and_return(request)
  end

  describe '#unique_key' do
    subject { worker.unique_key(request.id) }
    it { is_expected.to eq(request.id) }
  end

  describe '#perform' do
    subject { worker.perform(request.id, {}) }

    it do
      expect(PeriodicReport).to receive(:send_report_limited?).with(user.uid).and_return(false)
      expect(worker).to receive(:do_perform).with(request, {})
      subject
    end

    context 'duplicate job' do
      before do
        allow(worker).to receive(:user_requested_job?).and_return(true)
        create(:create_periodic_report_request, user: user, created_at: request.created_at - 3.seconds)
      end
      it do
        expect(request).to receive(:update).with(status: 'job_skipped')
        expect(worker).not_to receive(:do_perform)
        subject
      end
    end

    context 'sending DM is rate-limited' do
      before { allow(PeriodicReport).to receive(:send_report_limited?).with(user.uid).and_return(true) }
      it do
        expect(worker).to receive(:retry_current_report).with(request.id, {})
        expect(worker).not_to receive(:do_perform)
        subject
      end
    end
  end

  describe '#do_perform' do
    subject { worker.send(:do_perform, request, {}) }

    it do
      expect(request).to receive(:perform)
      subject
      expect(request.worker_context).to eq(described_class)
      expect(request.check_credentials).to be_truthy
      expect(request.check_interval).to be_falsey
      expect(request.check_following_status).to be_falsey
      expect(request.check_allotted_messages_count).to be_truthy
      expect(request.check_web_access).to be_truthy
    end

    context 'user_requested_job? returns true' do
      before do
        allow(worker).to receive(:user_requested_job?).and_return(true)
      end
      it do
        expect(request).to receive(:perform)
        subject
        expect(request.check_interval).to be_truthy
        expect(request.check_following_status).to be_truthy
      end
    end

    context 'batch_requested_job? returns true' do
      before do
        allow(worker).to receive(:batch_requested_job?).and_return(true)
      end
      it do
        expect(request).to receive(:perform)
        subject
        expect(request.check_allotted_messages_count).to be_truthy
      end
    end
  end
end
