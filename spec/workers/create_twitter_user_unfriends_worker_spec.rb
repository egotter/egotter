require 'rails_helper'

RSpec.describe CreateTwitterUserUnfriendsWorker do
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
    subject { worker.perform(twitter_user.id) }
    it do
      expect(worker).to receive(:import_uids).with(S3::Unfriendship, twitter_user).and_return([1, 2])
      expect(worker).to receive(:import_uids).with(S3::Unfollowership, twitter_user).and_return([2, 3])
      expect(worker).to receive(:import_uids).with(S3::MutualUnfriendship, twitter_user).and_return([3])
      expect(worker).to receive(:update_twitter_db_users).with([1, 2, 3], twitter_user.user_id, instance_of(String))
      expect(DeleteUnfriendshipsWorker).to receive(:perform_async).with(twitter_user.uid)
      subject
    end
  end

  describe '#import_uids' do
    let(:klass) { S3::Unfriendship }
    let(:uids) { [1] }
    subject { worker.send(:import_uids, klass, twitter_user) }
    before { allow(twitter_user).to receive(:calc_uids_for).with(klass).and_return(uids) }
    it do
      expect(klass).to receive(:import_from!).with(twitter_user.uid, uids)
      expect(twitter_user).to receive(:update_counter_cache_for).with(klass, uids.size)
      subject
    end
  end
end
