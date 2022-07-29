require 'rails_helper'

RSpec.describe TwitterDB::QueuedUser, type: :model do
  describe '.import_data' do
    let(:uids) { [1, 2, 3] }
    subject { described_class.import_data(uids) }
    before { create(:twitter_db_queued_user, uid: uids[0]) }

    it { expect { subject }.to change { described_class.all.size }.by(2) }

    context 'ActiveRecord::Deadlocked is raised' do
      before { allow(described_class).to receive(:import).with(any_args).and_raise(ActiveRecord::Deadlocked) }
      it { expect { subject }.to change { described_class.all.size }.by(2) }
    end
  end

  describe '#mark_uids_as_processing' do
    let(:uids) { [1, 2] }
    subject { described_class.mark_uids_as_processing(uids) }
    it do
      expect(described_class).to receive(:import_data).with([1, 2])
      subject
    end
  end

  describe '#mark_uids_as_processed' do
    let(:uids) { [1, 2] }
    subject { described_class.mark_uids_as_processed(uids) }
    it do
      expect(described_class).to receive_message_chain(:where, :update_all).
          with([1, 2]).with(processed_at: instance_of(ActiveSupport::TimeWithZone))
      subject
    end
  end

  describe '.delete_stale_records' do
    subject { described_class.delete_stale_records }
    before do
      create(:twitter_db_queued_user, uid: 1, processed_at: Time.zone.now, created_at: 10.hours.ago)
      create(:twitter_db_queued_user, uid: 2, processed_at: Time.zone.now, created_at: 5.hours.ago)
      create(:twitter_db_queued_user, uid: 3, processed_at: nil, created_at: 10.hours.ago)
      create(:twitter_db_queued_user, uid: 4, processed_at: nil, created_at: 5.hours.ago)
    end
    it do
      expect { subject }.to change { described_class.all.size }.by(-2)
      expect(described_class.pluck(:uid)).to eq([2, 4])
    end
  end
end
