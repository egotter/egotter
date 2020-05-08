require 'rails_helper'

RSpec.describe CreatePeriodicReportWorker do
  let(:user) { create(:user) }
  let(:request) do
    CreatePeriodicReportRequest.create(
        user: user
    )
  end
  let(:worker) { described_class.new }

  before do
    allow(request).to receive(:perform!)
  end

  describe '#unique_key' do
    subject { worker.unique_key(request.id) }
    it { is_expected.to eq(request.user_id) }
  end

  describe '#after_skip' do
    subject { worker.after_skip(request.id) }
    before do
      allow(CreatePeriodicReportRequest).to receive(:find).with(request.id).and_return(request)
      allow(worker).to receive(:user_requested_job?).and_return(true)
    end
    it do
      expect(request).to receive(:update).with(status: 'skipped')
      expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(request.user_id, interval_too_short: true)
      subject
    end
  end

  describe '#perform' do
    let(:task) { double('task') }
    subject { worker.perform(request.id) }
    before do
      allow(CreatePeriodicReportRequest).to receive(:find).with(request.id).and_return(request)
    end
    it do
      expect(CreatePeriodicReportTask).to receive(:new).with(request).and_return(task)
      expect(task).to receive(:start!)
      subject
      expect(request.worker_context).to eq(described_class)
      expect(request.check_credentials).to be_truthy
      expect(request.check_interval).to be_falsey
      expect(request.check_twitter_user).to be_falsey
    end

    context 'sending_dm_limited? returns true' do
      before do
        allow(worker).to receive(:sending_dm_limited?).with(user.uid).and_return(true)
      end
      it do
        expect(SkippedCreatePeriodicReportWorker).to receive(:perform_async).with(request.id, anything)
        expect(request).to receive(:update).with(status: 'limited')
        expect(CreatePeriodicReportTask).not_to receive(:new)
        subject
      end
    end

    context 'user_requested_job? returns true' do
      it do
        subject
        expect(request.check_interval).to be_falsey
      end
    end

    context 'user_requested_job? returns true' do
      subject { worker.perform(request.id, 'create_twitter_user' => true) }
      it do
        subject
        expect(request.check_twitter_user).to be_truthy
      end
    end
  end
end
