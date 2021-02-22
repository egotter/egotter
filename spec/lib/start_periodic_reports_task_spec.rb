require 'rails_helper'

RSpec.describe StartPeriodicReportsTask, type: :model do
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
    let(:user_ids) { [1, 2] }
    let(:instance) { described_class.new }
    subject { instance.start! }
    before { allow(instance).to receive(:initialize_user_ids).and_return(user_ids) }

    it do
      expect(instance).to receive(:create_requests).with(user_ids).and_return('requests')
      expect(instance).to receive(:create_jobs).with('requests')
      subject
    end
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

  describe '#create_requests' do
    let(:user_ids) { [1, 2] }
    subject { described_class.new.create_requests(user_ids) }
    before { create(:create_periodic_report_request, user_id: create(:user).id) }
    it do
      records = []
      expect { records = subject }.to change { CreatePeriodicReportRequest.all.size }.by(2)
      expect(records.size).to eq(2)
    end
  end

  describe '#create_jobs' do
    let(:requests) { [create(:create_periodic_report_request, user_id: create(:user).id)] }
    subject { described_class.new.create_jobs(requests) }
    it do
      requests.each.with_index do |request, i|
        expect(CreatePeriodicReportWorker).to receive(:perform_in).with(i.seconds, request.id, user_id: request.user_id, create_twitter_user: true)
      end
      subject
    end
  end

  describe '.morning_user_ids' do
    let(:user) { create(:user) }
    subject { described_class.morning_user_ids }
    before do
      allow(described_class).to receive(:premium_user_ids).and_return([1, 2])
      allow(described_class).to receive(:dm_received_user_ids).and_return([2, 3])
      allow(described_class).to receive(:new_user_ids).with(any_args).and_return([3, 4])
      allow(described_class).to receive(:reject_specific_period_stopped_user_ids).with([1, 2, 3, 4], :morning).and_return('result')
    end
    it { is_expected.to eq('result') }
  end

  describe '.afternoon_user_ids' do
    let(:user) { create(:user) }
    subject { described_class.afternoon_user_ids }
    before do
      allow(described_class).to receive(:premium_user_ids).and_return([1, 2])
      allow(described_class).to receive(:dm_received_user_ids).and_return([2, 3])
      allow(described_class).to receive(:new_user_ids).with(any_args).and_return([3, 4])
      allow(described_class).to receive(:reject_specific_period_stopped_user_ids).with([1, 2, 3, 4], :afternoon).and_return('result')
    end
    it { is_expected.to eq('result') }
  end

  describe '.night_user_ids' do
    let!(:user) { create(:user) }
    subject { described_class.night_user_ids }
    before do
      allow(described_class).to receive(:premium_user_ids).and_return([1, 2])
      allow(described_class).to receive(:dm_received_user_ids).and_return([2, 3])
      allow(described_class).to receive(:new_user_ids).with(any_args).and_return([3, 4])
    end
    it { is_expected.to eq([1, 2, 3, 4]) }
  end

  describe '#reject_specific_period_stopped_user_ids' do
    let(:users) { 2.times.map { create(:user) } }
    let(:user_ids) { users.map(&:id) }
    subject { described_class.reject_specific_period_stopped_user_ids(user_ids, :morning) }

    before do
      users.each { |user| user.create_periodic_report_setting! }
      users[0].periodic_report_setting.update!(morning: false)
    end

    it { is_expected.to eq([users[1].id]) }
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

  describe '.premium_user_ids' do
    subject { User.premium.pluck(:id) }
    it do
      expect(User).to receive_message_chain(:premium, :pluck).with(no_args).with(:id)
      subject
    end
  end

  describe '.reject_stop_requested_user_ids' do
    let(:user_ids) { [1, 2, 3] }
    subject { described_class.reject_stop_requested_user_ids(user_ids) }

    context 'unsubscribe is not requested' do
      it { is_expected.to match_array([1, 2, 3]) }
    end

    context 'unsubscribe is requested' do
      before { StopPeriodicReportRequest.create!(user_id: user_ids[1]) }
      it { is_expected.to match_array([1, 3]) }
    end
  end

  describe '.allotted_messages_will_expire_user_ids' do
  end
end
