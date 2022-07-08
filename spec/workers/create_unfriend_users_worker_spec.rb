require 'rails_helper'

RSpec.describe CreateUnfriendUsersWorker do
  describe '#perform' do
    let(:user_id) { 100 }
    let(:from_uid) { 0 }
    let(:uids) { [1, 2, 3] }
    subject { described_class.new.perform(user_id, from_uid, uids) }

    before do
      uids.each { |uid| create(:twitter_db_user, uid: uid) }
    end

    it do
      expect(UnfriendUser).to receive(:import_data).with(from_uid, any_args)
      subject
    end

    context 'missing_uids are found' do
      before do
        TwitterDB::User.where(uid: uids[0]).delete_all
      end

      it do
        expect(CreateTwitterDBUserWorker).to receive(:perform_async).with(uids.take(1), user_id: user_id, enqueued_by: described_class)
        subject
      end
    end
  end
end
