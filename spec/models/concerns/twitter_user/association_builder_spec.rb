require 'rails_helper'

RSpec.describe Concerns::TwitterUser::AssociationBuilder do
  let(:tu) do
    tu = build(:twitter_user)
    tu.friends = []
    tu.statuses = []
    tu
  end
  let(:friends) do
    3.times.to_a.map { |n| Hashie::Mash.new({id: n, screen_name: "sn#{n}"}) }
  end
  let(:statuses) do
    3.times.to_a.map { |n| Hashie::Mash.new(user: {id: n, screen_name: "sn#{n}"}) }
  end

  describe '#build_relations' do
    before { allow(tu).to receive(:fetch_relations).and_return({friends: friends, statuses: statuses}) }
    it 'calls build_user_relations' do
      expect(tu).to receive(:build_user_relations).with(:friends, friends)
      expect(tu).to receive(:build_user_relations).with(:followers, nil)
      tu.build_relations(nil, nil, :search)
    end

    it 'calls build_status_relations' do
      expect(tu).to receive(:build_status_relations).with(:statuses, statuses)
      expect(tu).to receive(:build_status_relations).with(:mentions, nil)
      expect(tu).to receive(:build_status_relations).with(:search_results, nil)
      expect(tu).to receive(:build_status_relations).with(:favorites, nil)
      tu.build_relations(nil, nil, :search)
    end
  end

  describe '#reject_relation_names' do
    context '#too_many_friends? returns true' do
      before { allow(tu).to receive(:too_many_friends?).and_return(true) }

      it 'includes :friends and :followers' do
        candidates = tu.send(:reject_relation_names, nil, :search)
        expect(candidates).to be_include(:friends)
        expect(candidates).to be_include(:followers)
      end
    end
  end

  describe '#build_user_relations' do
    context 'friends' do
      it 'builds friends' do
        tu.send(:build_user_relations, :friends, friends)
        tu.friends.each.with_index do |f, i|
          expect(f.uid).to eq(friends[i].id.to_s)
          expect(f.screen_name).to eq(friends[i].screen_name)
        end
      end
    end
  end

  describe '#build_status_relations' do
    context 'statuses' do
      it 'builds statuses' do
        tu.send(:build_status_relations, :statuses, statuses)
        tu.statuses.each.with_index do |s, i|
          expect(s.uid).to eq(statuses[i].user.id.to_s)
          expect(s.screen_name).to eq(statuses[i].user.screen_name)
        end
      end
    end
  end
end