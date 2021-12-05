require 'rails_helper'

RSpec.describe CreateTwitterDBUsersForMissingUidsWorker do
  let(:worker) { described_class.new }

  describe '#fetch_missing_uids' do
    let(:uids) { [1, 2, 3] }
    subject { worker.send(:fetch_missing_uids, uids) }
    before { create(:twitter_db_user, uid: 2) }
    it { is_expected.to eq([1, 3]) }
  end
end
