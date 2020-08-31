require 'rails_helper'

RSpec.describe ClusterFinder, type: :model do
  let(:instance) { described_class.new }
  let(:lists) do
    [
        double('List', id: 'id1', full_name: 'user1/name1-flower', member_count: 3),
        double('List', id: 'id2', full_name: 'user2/name2-flower', member_count: 10),
        double('List', id: 'id3', full_name: 'user3/name3-music', member_count: 15),
    ]
  end

  describe '#list_clusters' do

  end

  describe '#count_words' do
    subject { instance.send(:count_words, lists) }
    it { is_expected.to eq('flower' => 2, 'music' => 1, 'name1' => 1, 'name2' => 1, 'name3' => 1) }
  end

  describe '#filter_lists_by_words' do
    let(:words) { %w(name2 name1) }
    subject { instance.send(:filter_lists_by_words, lists, words) }
    it { is_expected.to eq([lists[1], lists[0]]) }
  end

  describe '#filter_lists_by_member_count' do
    let(:words) { %w(name2 name1) }
    subject { instance.send(:filter_lists_by_member_count, lists) }
    it { is_expected.to eq([lists[1], lists[2]]) }
  end

  describe '#filter_lists_by_total_members' do
    let(:words) { %w(name2 name1) }
    subject { instance.send(:filter_lists_by_member_count, lists) }
    it { is_expected.to eq([lists[1], lists[2]]) }
  end
end
