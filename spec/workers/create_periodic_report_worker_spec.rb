require 'rails_helper'

RSpec.describe CreatePeriodicReportWorker do
  let(:user) { create(:user) }
  let(:request) { create(:create_periodic_report_request, user: user) }
  let(:worker) { described_class.new }

  before do
    allow(request).to receive(:perform!)
    allow(CreatePeriodicReportRequest).to receive(:find).with(request.id).and_return(request)
  end

  describe '#unique_key' do
    subject { worker.unique_key(request.id) }
    it { is_expected.to eq(request.user_id) }
  end

  describe '#after_skip' do
    subject { worker.after_skip(request.id) }

    before do
      allow(CreatePeriodicReportRequest).to receive(:find).with(request.id).and_return(request)
    end

    it do
      expect(request).to receive(:update).with(status: 'job_skipped')
      subject
    end

    context 'user_requested_job? returns true' do
      let(:waiting_time) { CreatePeriodicReportMessageWorker::UNIQUE_IN + 3.seconds }

      before do
        allow(worker).to receive(:user_requested_job?).and_return(true)
      end

      it do
        expect(CreatePeriodicReportRequestIntervalTooShortMessageWorker).to receive(:perform_in).with(waiting_time, request.user_id)
        subject
      end
    end
  end

  describe '#timeout?' do
    subject { worker.timeout? }
    before { worker.instance_variable_set(:@start, start_time) }

    context 'start_time is 1 hour ago' do
      let(:start_time) { 1.hour.ago }
      it { expect(is_expected).to be_truthy }
    end

    context 'start_time is 10 seconds ago' do
      let(:start_time) { 10.seconds.ago }
      it { expect(is_expected).to be_truthy }
    end
  end

  describe '#after_timeout' do
    subject { worker.after_timeout(request.id) }
    before { worker.instance_variable_set(:@start, Time.zone.now) }
    it do
      subject
      expect(request.reload.status).to eq('timeout')
    end
  end

  describe '#perform' do
    subject { worker.perform(request.id, {}) }

    it do
      expect(worker).to receive(:do_perform).with(request, {})
      subject
    end

    context 'send_report? returns false' do
      before { allow(worker).to receive(:send_report?).with(user).and_return(false) }
      it do
        expect(SkippedCreatePeriodicReportWorker).to receive(:perform_async).with(request.id, anything)
        expect(request).to receive(:update).with(status: 'limited')
        expect(CreatePeriodicReportTask).not_to receive(:new)
        subject
      end
    end
  end

  describe '#do_perform' do
    let(:task) { double('task') }
    subject { worker.send(:do_perform, request, {}) }

    before do
      allow(CreatePeriodicReportTask).to receive(:new).with(request).and_return(task)
      allow(task).to receive(:start!)
    end

    it do
      expect(task).to receive(:start!)
      subject
      expect(request.worker_context).to eq(described_class)
      expect(request.check_credentials).to be_truthy
      expect(request.check_interval).to be_falsey
      expect(request.check_following_status).to be_falsey
      expect(request.check_allotted_messages_count).to be_truthy
      expect(request.check_web_access).to be_falsey
      expect(request.send_only_if_changed).to be_falsey
      expect(request.check_twitter_user).to be_truthy
    end

    context 'user_requested_job? returns true' do
      before do
        allow(worker).to receive(:user_requested_job?).and_return(true)
      end
      it do
        subject
        expect(request.check_interval).to be_truthy
        expect(request.check_following_status).to be_truthy
        expect(request.check_web_access).to be_truthy
      end
    end

    context 'batch_requested_job? returns true' do
      before do
        allow(worker).to receive(:batch_requested_job?).and_return(true)
      end
      it do
        subject
        expect(request.check_allotted_messages_count).to be_truthy
      end
    end

    context 'send_only_if_changed is specified' do
      [true, false].each do |value|
        context "#{value} is passed" do
          subject { worker.perform(request.id, 'send_only_if_changed' => value) }
          it do
            subject
            expect(request.send_only_if_changed).to eq(value)
          end
        end
      end
    end

    context 'create_twitter_user is specified' do
      [true, false].each do |value|
        context "#{value} is passed" do
          subject { worker.perform(request.id, 'create_twitter_user' => value) }
          it do
            subject
            expect(request.check_twitter_user).to eq(value)
          end
        end
      end
    end

  end
end
