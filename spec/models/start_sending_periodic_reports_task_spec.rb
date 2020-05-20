require 'rails_helper'

RSpec.describe StartSendingPeriodicReportsTask, type: :model do
  describe '#initialize' do
    context 'user_ids is passed' do
      subject { described_class.new(user_ids: 'user_ids') }
      it do
        expect(described_class).to receive(:reject_stop_requested_user_ids).with('user_ids')
        subject
      end
    end
  end

  describe '#start!' do
    let(:instance) {described_class.new}
    subject { instance.start! }

    context '@remind_only is set' do
      before { instance.instance_variable_set(:@remind_only, true) }
      it do
        expect(instance).to receive(:start_reminding!)
        subject
      end
    end

    context '@remind_only is not set' do
      it do
        expect(instance).to receive(:start_sending!)
        subject
      end
    end
  end

  describe '#start_sending!' do

  end

  describe '#start_reminding!' do

  end

  describe '#initialize_remind_only_user_ids' do

  end

  describe '#initialize_user_ids' do
    let(:start_date) { 'start_date' }
    let(:end_date) { 'end_date' }
    subject { described_class.new(start_date: start_date, end_date: end_date).initialize_user_ids }

    it do
      expect(described_class).to receive(:dm_received_user_ids).and_return([1, 2])
      expect(described_class).to receive(:recent_access_user_ids).with(start_date, end_date).and_return([2, 3])
      expect(described_class).to receive(:new_user_ids).with(start_date, end_date).and_return([3, 4])
      is_expected.to match_array([1, 2, 3, 4])
    end
  end

  describe '.dm_received_user_ids' do
    let(:users) { 2.times.map { create(:user) } }
    subject { described_class.dm_received_user_ids }

    before { GlobalDirectMessageReceivedFlag.new.received(users[1].uid) }

    it do
      expect(described_class).to receive(:reject_stop_requested_user_ids).with([users[1].id]).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '.recent_access_user_ids' do
    let(:users) { 3.times.map { create(:user) } }
    subject { described_class.recent_access_user_ids }

    before do
      users[0].access_days.create!(date: 1.day.ago.to_date, created_at: 1.day.ago)
      users[1].access_days.create!(date: 10.hours.ago.to_date, created_at: 10.hours.ago)
      users[2].access_days.create!(date: 1.hours.ago.to_date, created_at: 1.hour.ago)
    end

    it do
      expect(described_class).to receive(:reject_stop_requested_user_ids).with([users[1].id]).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '.new_user_ids' do
    let(:users) { 2.times.map { create(:user) } }
    subject { described_class.new_user_ids }

    before do
      users[0].update(created_at: 2.day.ago)
      users[1].update(created_at: 10.hours.ago)
    end

    it do
      expect(described_class).to receive(:reject_stop_requested_user_ids).with([users[1].id]).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '.reject_stop_requested_user_ids' do
    let(:user_ids) { [1, 2, 3] }
    subject { described_class.reject_stop_requested_user_ids(user_ids) }
    context 'unsubscribe is requested' do
      before { StopPeriodicReportRequest.create!(user_id: user_ids[1]) }
      it { is_expected.to match_array([1, 3]) }
    end
  end

  describe '.allotted_messages_will_expire_user_ids' do
  end
end
