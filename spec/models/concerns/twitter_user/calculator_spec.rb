require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Calculator do
  let(:twitter_user) { create(:twitter_user) }
  let(:friend_uids) { [1, 2, 3] }
  let(:follower_uids) { [2, 3, 4] }

  before do
    allow(twitter_user).to receive(:friend_uids).and_return(friend_uids)
    allow(twitter_user).to receive(:follower_uids).and_return(follower_uids)
  end

  describe '#calc_one_sided_friend_uids' do
    it do
      expect(twitter_user.calc_one_sided_friend_uids).to match_array(friend_uids - follower_uids)
    end
  end

  describe '#calc_one_sided_follower_uids' do
    it do
      expect(twitter_user.calc_one_sided_follower_uids).to match_array(follower_uids - friend_uids)
    end
  end

  describe '#calc_mutual_friend_uids' do
    it do
      expect(twitter_user.calc_mutual_friend_uids).to match_array(friend_uids & follower_uids)
    end
  end

  describe '#calc_favorite_friend_uids' do
    before do
      allow(twitter_user).to receive(:calc_favorite_uids).and_return([1, 1, 2, 3, 3, 3])
    end
    context 'With uniq: true' do
      it do
        expect(twitter_user.calc_favorite_friend_uids(uniq: true)).to match_array([3, 1, 2])
      end
    end
    context 'With uniq: false' do
      it do
        expect(twitter_user.calc_favorite_friend_uids(uniq: false)).to match_array([1, 1, 2, 3, 3, 3])
      end
    end
  end

  describe '#calc_close_friend_uids' do
    context 'With mentions.any? == true' do
      before do
        allow(twitter_user).to receive(:mentions).and_return([1])
      end

    end
    context 'With mentions.any? == false' do
      before do
        allow(twitter_user).to receive(:mentions).and_return([])
      end

    end
  end

  describe '#calc_new_friend_uids' do
    let(:newer) { create(:twitter_user, created_at: twitter_user.created_at + 1.second) }
    before do
      newer.update(uid: twitter_user.uid) # Avoid recently updated error
    end
    it { expect(newer.calc_new_friend_uids).to match_array(newer.friend_uids - twitter_user.friend_uids) }
  end

  describe '#calc_new_follower_uids' do
    let(:newer) { create(:twitter_user, created_at: twitter_user.created_at + 1.second) }
    before do
      newer.update(uid: twitter_user.uid) # Avoid recently updated error
    end
    it { expect(newer.calc_new_follower_uids).to match_array(newer.follower_uids - twitter_user.follower_uids) }
  end
end
