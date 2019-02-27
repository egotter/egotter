require 'rails_helper'

RSpec.describe Concerns::TwitterUser::AssociationBuilder do
  let(:twitter_user) { TwitterUser.new }

  describe '#build_friends_and_followers' do
    context 'For friends' do
      let(:friend_ids) { [1, 2, 3] }
      before { twitter_user.build_friends_and_followers(friend_ids, nil) }
      it do
        expect(twitter_user.instance_variable_get(:@friend_uids)).to match_array(friend_ids)
        expect(twitter_user.friends_size).to eq(friend_ids.size)
      end
    end

    context 'For followers' do
      let(:follower_ids) { [2, 3, 4] }
      before { twitter_user.build_friends_and_followers(nil, follower_ids) }
      it do
        expect(twitter_user.instance_variable_get(:@follower_uids)).to match_array(follower_ids)
        expect(twitter_user.followers_size).to eq(follower_ids.size)
      end
    end
  end

  describe '#build_other_relations' do
    let(:relations) { {user_timeline: [status]} }
    before { twitter_user.build_other_relations(relations) }

    context 'For statuses' do
      let(:status) { Hashie::Mash.new(text: 'status', user: {id: 1, screen_name: 'sn'}) }

      it do
        expect(twitter_user.statuses[0].text).to eq(status.text)
        expect(twitter_user.statuses.size).to eq(relations[:user_timeline].size)
      end
    end
  end
end