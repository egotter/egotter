require 'rails_helper'

RSpec.describe CreateTwitterUserCloseFriendsWorker do
  let(:user) { create(:user) }
  let(:twitter_user) { create(:twitter_user, user_id: user.id) }
  let(:worker) { described_class.new }

  before do
    allow(TwitterUser).to receive(:find).with(twitter_user.id).and_return(twitter_user)
    allow(User).to receive(:find_by).with(id: twitter_user.user_id).and_return(user)
  end

  describe '#after_skip' do
    subject { worker.after_skip(twitter_user.id) }
    it do
      expect(worker.logger).to receive(:warn).with(instance_of(String))
      subject
    end
  end

  describe '#perform' do
    subject { worker.perform(twitter_user.id) }
    it do
      expect(worker).to receive(:import_close_friends).with(twitter_user, user)
      expect(worker).to receive(:import_favorite_friends).with(twitter_user, user)
      expect(CloseFriendship).to receive(:delete_by_uid).with(twitter_user.uid)
      expect(FavoriteFriendship).to receive(:delete_by_uid).with(twitter_user.uid)
      subject
    end
  end

  describe '#import_close_friends' do
    let(:uids) { [1] }
    subject { worker.send(:import_close_friends, twitter_user, user) }
    before do
      allow(twitter_user).to receive(:calc_uids_for).with(S3::CloseFriendship, login_user: user).and_return(uids)
    end
    it do
      expect(S3::CloseFriendship).to receive(:import_from!).with(twitter_user.uid, uids)
      expect(worker).to receive(:update_twitter_db_users).with(uids, twitter_user.user_id)
      subject
    end
  end

  describe '#import_favorite_friends' do
    let(:uids) { [1] }
    subject { worker.send(:import_favorite_friends, twitter_user, user) }
    before do
      allow(twitter_user).to receive(:calc_uids_for).with(S3::FavoriteFriendship, login_user: user).and_return(uids)
    end
    it do
      expect(S3::FavoriteFriendship).to receive(:import_from!).with(twitter_user.uid, uids)
      expect(worker).to receive(:update_twitter_db_users).with(uids, twitter_user.user_id)
      subject
    end
  end

  describe '#update_twitter_db_users' do
    let(:uids) { [1] }
    subject { worker.send(:update_twitter_db_users, uids, user.id) }
    before { Redis.client.flushall }
    it do
      expect(CreateHighPriorityTwitterDBUserWorker).to receive(:compress_and_perform_async).with(uids, user_id: user.id, enqueued_by: worker.class)
      subject
    end
  end
end
