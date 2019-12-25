require 'rails_helper'

RSpec.describe StartSendingPromptReportsWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
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
