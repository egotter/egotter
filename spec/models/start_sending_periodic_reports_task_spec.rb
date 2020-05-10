require 'rails_helper'

RSpec.describe StartSendingPeriodicReportsTask, type: :model do
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

  describe '.recent_access_user_ids' do
    let(:users) { 3.times.map { create(:user) } }
    subject { described_class.recent_access_user_ids }

    before do
      users[0].access_days.create!(date: 1.day.ago.to_date, created_at: 1.day.ago)
      users[1].access_days.create!(date: 10.hours.ago.to_date, created_at: 10.hours.ago)
      users[2].access_days.create!(date: 1.hours.ago.to_date, created_at: 1.hour.ago)
    end

    it { is_expected.to match_array([users[1].id]) }
  end

  describe '.new_user_ids' do
    let(:users) { 2.times.map { create(:user) } }
    subject { described_class.new_user_ids }

    before do
      users[0].update(created_at: 2.day.ago)
      users[1].update(created_at: 10.hours.ago)
    end

    it { is_expected.to match_array([users[1].id]) }
  end
end
