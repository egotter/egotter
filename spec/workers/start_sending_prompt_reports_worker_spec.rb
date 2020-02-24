require 'rails_helper'

RSpec.describe StartSendingPromptReportsWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:options) { 'options' }
    subject { worker.perform(options) }

    context 'CallCreateDirectMessageEventCount.rate_limited? returns true' do
      before { allow(CallCreateDirectMessageEventCount).to receive(:rate_limited?).and_return(true) }
      it do
        expect(StartSendingPromptReportsWorker).to receive(:perform_in).with(30.minutes, options)
        expect(worker).not_to receive(:start_queueing)
        subject
      end
    end

    context '#queueing_interval_too_short? returns false' do
      before { allow(worker).to receive(:queueing_interval_too_short?).with(options).and_return(false) }
      it do
        expect(worker).to receive(:start_queueing)
        subject
      end
    end

    context '#queueing_interval_too_short? returns true' do
      before do
        allow(worker).to receive(:queueing_interval_too_short?).with(options).and_return(true)
        allow(worker).to receive(:next_wait_time).with(anything).and_return(123)
      end
      it do
        expect(StartSendingPromptReportsWorker).to receive(:perform_in).with(123, options)
        expect(worker).not_to receive(:start_queueing)
        subject
      end
    end
  end

  describe '#queueing_interval_too_short?' do
    let(:time) { 'time' }
    let(:options) { {'last_queueing_started_at' => time} }
    subject { worker.send(:queueing_interval_too_short?, options) }

    before { allow(worker).to receive(:next_wait_time).with(time).and_return(wait_time) }

    context 'wait_time is greater than zero' do
      let(:wait_time) { 1 }
      it { is_expected.to be_truthy }
    end

    context 'wait_time is zero' do
      let(:wait_time) { 0 }
      it { is_expected.to be_falsey }
    end

    context 'wait_time is less than zero' do
      let(:wait_time) { -1 }
      it { is_expected.to be_falsey }
    end
  end

  describe '#next_wait_time' do
    subject { worker.next_wait_time(previous_started_at) }

    it { expect(described_class::QUEUEING_INTERVAL).to eq(CreatePromptReportRequest::PROCESS_REQUEST_INTERVAL) }

    context 'previous_started_at is nil' do
      let(:previous_started_at) { nil }
      it { is_expected.to eq(-1) }
    end

    context 'previous_started_at is before QUEUEING_INTERVAL.ago' do
      let(:previous_started_at) { (described_class::QUEUEING_INTERVAL + 1.second).ago.to_s }
      it { is_expected.to be < 0 }
    end

    context 'previous_started_at is after to QUEUEING_INTERVAL.ago' do
      let(:previous_started_at) { (described_class::QUEUEING_INTERVAL - 1.second).ago.to_s }
      before { allow(worker).to receive(:unique_in).and_return(10.seconds) }
      it { is_expected.to be > 10 }
    end
  end

  describe '#start_queueing' do
    let(:task) { instance_double(StartSendingPromptReportsTask) }
    let(:users) { double('users') }
    let(:requests) { double('requests') }
    subject { worker.perform }

    before do
      allow(StartSendingPromptReportsTask).to receive(:new).and_return(task)
      allow(task).to receive(:ids_stats).and_return('{}')
      allow(task).to receive(:users).and_return(users)
    end

    it do
      expect(worker).to receive(:create_requests).with(users).and_return(requests)
      expect(worker).to receive(:enqueue_requests).with(requests, any_args)
      expect { subject }.to change { StartSendingPromptReportsLog.all.size }.by(1)
    end
  end


  describe '#create_requests' do
    let(:users) { 10.times.map { create(:user) } }
    subject { worker.create_requests(users) }
    it do
      users.each { |user| expect(CreatePromptReportRequest).to receive(:new).with(user_id: user.id).and_call_original }
      expect { subject }.to change { CreatePromptReportRequest.all.size }.by(users.size)
      expect(subject).to all(satisfy { |r| r.persisted? })
    end
  end

  describe '#enqueue_requests' do
    let(:users) { 10.times.map { create(:user) } }
    let(:requests) { users.map { |user| create(:create_prompt_report_request, user_id: user.id) } }
    subject { worker.enqueue_requests(requests, Time.zone.now) }

    it do
      requests.each do |request|
        expect(CreatePromptReportWorker).to receive(:perform_async).with(request.id, hash_including(user_id: request.user_id))
      end
      subject
    end
  end
end
