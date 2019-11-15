require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Utils do
  subject(:twitter_user) { build(:twitter_user) }

  describe '#friend_uids' do
    context 'With new record' do
      before { twitter_user.instance_variable_set(:@friend_uids, 'hello') }
      it do
        expect(twitter_user.friend_uids).to eq('hello')
      end
    end

    context 'With persisted records' do
      before { twitter_user.save! }

      context 'EFS returns the result' do
        let(:friend_uids) { [1, 2, 3] }
        before do
          allow(Efs::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(friend_uids: friend_uids)
        end

        it do
          expect(twitter_user.friend_uids).to match_array(friend_uids)
        end
      end

      context 'S3 returns the result' do
        let(:friend_uids) { [1, 2, 3] }
        before do
          allow(Efs::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(nil)
          allow(S3::Friendship).to receive(:find_by).with(twitter_user_id: twitter_user.id).and_return(friend_uids: friend_uids)
        end

        it do
          expect(twitter_user.friend_uids).to match_array(friend_uids)
        end
      end
    end
  end

  describe '#follower_uids' do
    context 'With new record' do
      before { twitter_user.instance_variable_set(:@follower_uids, 'hello') }
      it do
        expect(twitter_user.follower_uids).to eq('hello')
      end
    end

    context 'With persisted records' do
      before { twitter_user.save! }

      context 'EFS returns the result' do
        let(:follower_uids) { [1, 2, 3] }
        before do
          allow(Efs::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(follower_uids: follower_uids)
        end

        it do
          expect(twitter_user.follower_uids).to match_array(follower_uids)
        end
      end

      context 'S3 returns the result' do
        let(:follower_uids) { [1, 2, 3] }
        before do
          allow(Efs::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(nil)
          allow(S3::Followership).to receive(:find_by).with(twitter_user_id: twitter_user.id).and_return(follower_uids: follower_uids)
        end

        it do
          expect(twitter_user.follower_uids).to match_array(follower_uids)
        end
      end
    end
  end
end
