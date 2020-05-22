require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Api do
  let(:twitter_user) { create(:twitter_user, with_relations: true) }

  describe '#mutual_friend_uids' do
    subject { twitter_user.mutual_friend_uids }
    it do
      expect(twitter_user).to receive_message_chain(:mutual_friendships, :pluck).with(:friend_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#common_mutual_friend_uids' do
    let(:other) { create(:twitter_user, with_relations: true) }
    subject { twitter_user.common_mutual_friend_uids(other) }
    it do
      expect(twitter_user).to receive(:mutual_friend_uids).and_return([1, 2, 3])
      expect(other).to receive(:mutual_friend_uids).and_return([2, 3, 4])
      is_expected.to eq([2, 3])
    end
  end

  describe '#common_mutual_friends' do
    let(:other) { create(:twitter_user, with_relations: true) }
    subject { twitter_user.common_mutual_friends(other) }
    before do
      allow(twitter_user).to receive(:common_mutual_friend_uids).with(other).and_return('uids')
    end
    it do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: 'uids').and_return('result')
      is_expected.to eq('result')
    end
  end
end
