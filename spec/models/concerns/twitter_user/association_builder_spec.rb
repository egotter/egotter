require 'rails_helper'

RSpec.describe Concerns::TwitterUser::AssociationBuilder do
  let(:twitter_user) { TwitterUser.new }

  describe '#build_relations' do
    let(:client) { nil }
    let(:login_user) { nil }

    let(:friends) { 3.times.map { |n| Hashie::Mash.new({id: n, screen_name: "sn#{n}"}) } }
    let(:statuses) { 3.times.map { |n| Hashie::Mash.new(user: {id: n, screen_name: "sn#{n}"}) } }
    let(:relations) do
      {
        friends: friends,
        followers: [],
        user_timeline: statuses,
        mentions_timeline: [],
        search: [],
        favorites: []
      }
    end

    before do
      allow(twitter_user).to receive(:fetch_relations).and_return(relations)
    end

    it 'builds friends' do
      twitter_user.build_relations(client, login_user, :search)
      expect(twitter_user.friends.map(&:uid).map(&:to_i)).to eq(friends.map(&:id))
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