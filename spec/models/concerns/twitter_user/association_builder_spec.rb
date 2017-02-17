require 'rails_helper'

RSpec.describe Concerns::TwitterUser::AssociationBuilder do
  let(:status) { Hashie::Mash.new({text: 'status', user: {id: 1, screen_name: 'sn'}}) }
  let(:relations) { {friend_ids: [1, 2, 3], follower_ids: [4, 5], user_timeline: [status]} }
  let(:twitter_user) { TwitterUser.new }

  describe '#build_friends_and_followers' do
    before { twitter_user.build_friends_and_followers(relations) }
    it 'builds friends and followers' do
      expect(twitter_user.friendships.map(&:friend_uid)).to match_array(relations[:friend_ids])
      expect(twitter_user.followerships.map(&:follower_uid)).to match_array(relations[:follower_ids])
      expect(twitter_user.friends_size).to eq(relations[:friend_ids].size)
      expect(twitter_user.followers_size).to eq(relations[:follower_ids].size)
    end
  end

  describe '#build_other_relations' do
    before { twitter_user.build_other_relations(relations) }
    it 'builds other relations' do
      expect(twitter_user.statuses.size).to eq(relations[:user_timeline].size)
    end
  end
end