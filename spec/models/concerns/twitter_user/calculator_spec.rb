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

  describe '#calc_unfriend_uids' do
    let(:builder) { UnfriendsBuilder.new(twitter_user) }
    before { twitter_user.instance_variable_set(:@unfriends_builder, builder) }
    it do
      expect(builder).to receive(:unfriends).with(no_args).and_call_original
      twitter_user.calc_unfriend_uids
    end
  end

  describe '#calc_unfollower_uids' do
    let(:builder) { UnfriendsBuilder.new(twitter_user) }
    before { twitter_user.instance_variable_set(:@unfriends_builder, builder) }
    it do
      expect(builder).to receive(:unfollowers).with(no_args).and_call_original
      twitter_user.calc_unfollower_uids
    end
  end
end
