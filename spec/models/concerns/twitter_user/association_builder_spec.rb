require 'rails_helper'

RSpec.describe Concerns::TwitterUser::AssociationBuilder do
  let(:twitter_user) { TwitterUser.new(uid: 1, screen_name: 'sn', user_info: {}.to_json) }

  describe '#build_relations' do
    let(:client) { nil }
    let(:login_user) { nil }

    let(:friends) { 3.times.map { |n| Hashie::Mash.new({id: n, screen_name: "sn#{n}"}) } }
    let(:followers) { 3.times.map { |n| Hashie::Mash.new({id: n * 2, screen_name: "sn#{n}"}) } }
    let(:statuses) { 3.times.map { |n| Hashie::Mash.new(user: {id: n, screen_name: "sn#{n}"}) } }
    let(:relations) do
      {
        friends: friends,
        followers: followers,
        user_timeline: statuses,
        mentions_timeline: [],
        search: [],
        favorites: []
      }
    end

    before do
      allow(twitter_user).to receive(:fetch_relations).and_return(relations)
    end

    it 'builds friendships' do
      twitter_user.build_relations(client, login_user, :search)
      expect(twitter_user.friendships.map(&:friend_uid)).to eq(friends.map(&:id))
    end

    it 'builds followerships' do
      twitter_user.build_relations(client, login_user, :search)
      expect(twitter_user.followerships.map(&:follower_uid)).to eq(followers.map(&:id))
    end
  end

  describe '#reject_relation_names' do
    context '#too_many_friends? returns true' do
      before { allow(twitter_user).to receive(:too_many_friends?).and_return(true) }

      it 'includes :friends and :followers' do
        candidates = twitter_user.send(:reject_relation_names, nil, :search)
        expect(candidates).to be_include(:friends)
        expect(candidates).to be_include(:followers)
      end
    end
  end
end