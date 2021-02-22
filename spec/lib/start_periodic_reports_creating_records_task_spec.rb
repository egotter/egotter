require 'rails_helper'

RSpec.describe StartPeriodicReportsCreatingRecordsTask, type: :model do
  let(:instance) { described_class.new }

  describe '#start!' do
    let(:user_ids) { [1, 2] }
    subject { instance.start! }
    before { allow(instance).to receive(:initialize_user_ids).and_return(user_ids) }

    it do
      expect(instance).to receive(:create_requests).with(user_ids).and_return('requests')
      expect(instance).to receive(:create_jobs).with('requests')
      subject
    end
  end

  describe '#initialize_user_ids' do
    subject { instance.initialize_user_ids }
    it do
      expect(StartPeriodicReportsTask).to receive(:morning_user_ids).and_return([1, 2])
      is_expected.to eq([1, 2])
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
    subject { described_class.new.create_jobs(requests) }
    it do
      requests.each.with_index do |request, i|
        expect(CreateReportTwitterUserWorker).to receive(:perform_in).with(i.seconds, request.id, context: :reporting)
      end
      subject
    end
  end
end
