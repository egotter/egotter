require 'rails_helper'

RSpec.describe StartPeriodicReportsCreatingRecordsTask, type: :model do
  let(:instance) { described_class.new(period: nil) }

  describe '#initialize' do
    subject { described_class.new(period: period) }
    context 'period is morning' do
      let(:period) { 'morning' }
      it do
        expect(StartPeriodicReportsTask).to receive(:morning_user_ids)
        subject
      end
    end
    context 'period is afternoon' do
      let(:period) { 'afternoon' }
      it do
        expect(StartPeriodicReportsTask).to receive(:afternoon_user_ids)
        subject
      end
    end
    context 'period is night' do
      let(:period) { 'night' }
      it do
        expect(StartPeriodicReportsTask).to receive(:night_user_ids)
        subject
      end
    end
  end

  describe '#start' do
    let(:user_ids) { [1, 2] }
    subject { instance.start }
    before do
      instance.instance_variable_set(:@user_ids, user_ids)
      instance.instance_variable_set(:@threads, 111)
    end

    it do
      expect(instance).to receive(:create_requests).with(user_ids).and_return('requests')
      expect(instance).to receive(:run_jobs).with('requests', 111)
      subject
    end
  end

  describe '#create_requests' do
    let(:users) { [create(:user), create(:user)] }
    let(:user_ids) { users.map(&:id) }
    subject { instance.create_requests(user_ids) }
    it do
      records = []
      expect { records = subject }.to change { CreateTwitterUserRequest.all.size }.by(2)
      expect(records.size).to eq(2)
    end
  end

  describe '#create_jobs' do
    let(:requests) { [create(:create_twitter_user_request, user_id: create(:user).id)] }
    subject { instance.create_jobs(requests) }
    it do
      requests.each do |request|
        expect(CreateReportTwitterUserWorker).to receive(:perform_async).with(request.id, period: 'none')
      end
      subject
    end
  end
end
