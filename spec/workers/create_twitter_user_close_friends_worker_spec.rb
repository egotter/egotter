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
      expect(Airbag).to receive(:warn).with(instance_of(String))
      subject
    end
  end

  describe '#perform' do
    let(:close_friend_uids) { [1, 2, 3] }
    let(:favorite_friend_uids) { [3, 4, 5, 6] }
    subject { worker.perform(twitter_user.id) }
    it do
      expect(twitter_user).to receive(:calc_uids_for).with(S3::CloseFriendship, login_user: user).and_return(close_friend_uids)
      expect(S3::CloseFriendship).to receive(:import_from!).with(twitter_user.uid, close_friend_uids)

      expect(twitter_user).to receive(:calc_uids_for).with(S3::FavoriteFriendship, login_user: user).and_return(favorite_friend_uids)
      expect(S3::FavoriteFriendship).to receive(:import_from!).with(twitter_user.uid, favorite_friend_uids)

      expect(CreateTwitterDBUserWorker).to receive(:perform_async).with([1, 2, 3, 4, 5, 6], user_id: user.id, enqueued_by: described_class)

      expect(CloseFriendship).to receive(:delete_by_uid).with(twitter_user.uid)
      expect(FavoriteFriendship).to receive(:delete_by_uid).with(twitter_user.uid)
      subject
    end
  end
end
