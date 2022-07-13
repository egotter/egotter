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
end
