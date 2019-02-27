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
      it do
        expect(S3::Friendship).to receive(:find_by).with(twitter_user_id: twitter_user.id).and_return(friend_uids: nil)
        twitter_user.friend_uids
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
      it do
        expect(S3::Followership).to receive(:find_by).with(twitter_user_id: twitter_user.id).and_return(follower_uids: nil)
        twitter_user.follower_uids
      end
    end
  end
end
