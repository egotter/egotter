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
    before { instance.instance_variable_set(:@user_ids, user_ids) }
    it do
      expect(instance).to receive(:create_requests).with(user_ids).and_return('requests')
      expect(instance).to receive(:create_jobs).with('requests')
      subject
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
      requests.each do |request|
        expect(CreatePeriodicReportWorker).to receive(:perform_in).with(instance_of(Integer), request.id, user_id: request.user_id)
      end
      subject
    end
  end

  describe '.periodic_base_user_ids' do
    subject { described_class.periodic_base_user_ids }
    before do
      allow(described_class).to receive(:dm_received_user_ids).and_return([1, 2])
      allow(described_class).to receive(:new_user_ids).and_return([2, 3])
      allow(described_class).to receive(:premium_user_ids).and_return([1, 4])
    end
    it do
      expect(described_class).to receive(:reject_banned_user_ids).and_return([1, 2, 3]).and_return([1, 3])
      expect(described_class).to receive(:reject_stop_requested_user_ids).and_return([1, 3, 4]).and_return([3, 4])
      is_expected.to eq([3, 4])
    end
  end

  describe '.morning_user_ids' do
    subject { described_class.morning_user_ids }
    it do
      expect(described_class).to receive(:periodic_base_user_ids).and_return([1, 2, 3])
      expect(described_class).to receive(:reject_specific_period_stopped_user_ids).with([1, 2, 3], :morning).and_return([2, 3])
      is_expected.to eq([2, 3])
    end
  end

  describe '.afternoon_user_ids' do
    subject { described_class.afternoon_user_ids }
    it do
      expect(described_class).to receive(:periodic_base_user_ids).and_return([1, 2, 3])
      expect(described_class).to receive(:reject_specific_period_stopped_user_ids).with([1, 2, 3], :afternoon).and_return([2, 3])
      is_expected.to eq([2, 3])
    end
  end

  describe '.night_user_ids' do
    subject { described_class.night_user_ids }
    it do
      expect(described_class).to receive(:periodic_base_user_ids).and_return([1, 2, 3])
      is_expected.to eq([1, 2, 3])
    end
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
    let(:users) do
      [
          create(:user),
          create(:user, authorized: false),
      ]
    end
    subject { described_class.dm_received_user_ids }
    before { allow(DirectMessageReceiveLog).to receive(:received_sender_ids).and_return(users.map(&:uid)) }
    it do
      is_expected.to eq([users[0].id])
    end
  end

  describe '.new_user_ids' do
    let(:users) do
      [
          create(:user, created_at: 2.day.ago),
          create(:user, created_at: 10.hours.ago),
          create(:user, authorized: false, created_at: 5.hours.ago),
      ]
    end
    subject { described_class.new_user_ids }
    before { users }
    it { is_expected.to eq([users[1].id]) }
  end

  describe '.premium_user_ids' do
    subject { described_class.premium_user_ids }
    it do
      expect(User).to receive_message_chain(:premium, :authorized, :pluck).with(no_args).with(no_args).with(:id)
      subject
    end
  end

  describe '.reject_stop_requested_user_ids' do
    let(:user_ids) { [1, 2, 3] }
    subject { described_class.reject_stop_requested_user_ids(user_ids) }

    context 'stop is not requested' do
      it { is_expected.to match_array([1, 2, 3]) }
    end

    context 'stop is requested' do
      before { StopPeriodicReportRequest.create!(user_id: user_ids[1]) }
      it { is_expected.to match_array([1, 3]) }
    end
  end

  describe '.reject_remind_requested_user_ids' do
    let(:user_ids) { [1, 2, 3] }
    subject { described_class.reject_remind_requested_user_ids(user_ids) }

    context 'remind is not requested' do
      it { is_expected.to match_array([1, 2, 3]) }
    end

    context 'remind is requested' do
      before { RemindPeriodicReportRequest.create!(user_id: user_ids[1]) }
      it { is_expected.to match_array([1, 3]) }
    end
  end

  describe '.reject_banned_user_ids' do
    let(:user_ids) { [create(:user).id, create(:user).id] }
    subject { described_class.reject_banned_user_ids(user_ids) }

    context 'ban is not requested' do
      it { is_expected.to match_array(user_ids) }
    end

    context 'ban is requested' do
      before { create(:banned_user, user_id: user_ids[0]) }
      it { is_expected.to match_array([user_ids[1]]) }
    end
  end
end
