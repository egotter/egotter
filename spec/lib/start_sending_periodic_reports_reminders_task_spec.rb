require 'rails_helper'

RSpec.describe StartSendingPeriodicReportsRemindersTask, type: :model do
  let(:instance) { described_class.new }

  describe '#start!' do
    let(:user_ids) { [1, 2] }
    subject { instance.start! }
    before { allow(instance).to receive(:initialize_user_ids).and_return(user_ids) }

    it do
      expect(instance).to receive(:create_requests).with(user_ids)
      expect(instance).to receive(:create_jobs).with(user_ids)
      subject
    end
  end

  describe '#initialize_user_ids' do
    subject { instance.initialize_user_ids }
    it do
      expect(StartSendingPeriodicReportsTask).to receive(:allotted_messages_will_expire_user_ids).and_return([1, 2, 2])
      is_expected.to eq([1, 2])
    end
  end

  describe '#create_requests' do
    let(:user_ids) { [1, 2] }
    subject { instance.create_requests(user_ids) }
    it { expect { subject }.to change { RemindPeriodicReportRequest.all.size }.by(user_ids.size) }
  end

  describe '#create_jobs' do
    let(:user_ids) { [1, 2] }
    subject { instance.create_jobs(user_ids) }
    it do
      user_ids.each.with_index do |user_id, i|
        expect(CreatePeriodicReportAllottedMessagesWillExpireMessageWorker).to receive(:perform_in).with(i.seconds, user_id)
      end
      subject
    end
  end
end
