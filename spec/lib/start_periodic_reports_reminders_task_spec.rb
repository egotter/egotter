require 'rails_helper'

RSpec.describe StartPeriodicReportsRemindersTask, type: :model do
  let(:instance) { described_class.new }

  describe '#start' do
    let(:user_ids) { [1, 2] }
    subject { instance.start }
    before { allow(StartPeriodicReportsTask).to receive(:allotted_messages_will_expire_user_ids).and_return(user_ids) }

    it do
      expect(instance).to receive(:create_requests).with(user_ids)
      expect(instance).to receive(:create_jobs).with(user_ids)
      subject
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
      user_ids.each do |user_id|
        expect(CreatePeriodicReportAllottedMessagesWillExpireMessageWorker).to receive(:perform_async).with(user_id)
      end
      subject
    end
  end
end
