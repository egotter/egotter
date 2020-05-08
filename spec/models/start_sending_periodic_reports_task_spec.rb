require 'rails_helper'

RSpec.describe StartSendingPeriodicReportsTask, type: :model do
  describe '#initialize_user_ids' do
    subject { described_class.new(start_date: 'start_date').initialize_user_ids }
    it do
      expect(described_class).to receive(:dm_received_user_ids).and_return([1, 2])
      expect(described_class).to receive(:recent_access_user_ids).with('start_date').and_return([2, 3])
      expect(described_class).to receive(:new_user_ids).with('start_date').and_return([3, 4])
      is_expected.to match_array([1, 2, 3, 4])
    end
  end
end
