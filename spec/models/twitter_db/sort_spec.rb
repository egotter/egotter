require 'rails_helper'

RSpec.describe TwitterDB::Sort, type: :model do
  describe '#apply' do
    let(:query) { TwitterDB::User }
    let(:users) do
      [
          create(:twitter_db_user, uid: 1, friends_count: 1, followers_count: 2, statuses_count: 2),
          create(:twitter_db_user, uid: 2, friends_count: 3, followers_count: 1, statuses_count: 3),
          create(:twitter_db_user, uid: 3, friends_count: 2, followers_count: 3, statuses_count: 1),
      ]
    end
    let(:instance) { described_class.new(value) }
    subject { instance.apply(query, users.map(&:uid)) }

    context "desc is passed" do
      let(:value) { 'desc' }
      it { is_expected.to eq([1, 2, 3]) }
    end

    context "asc is passed" do
      let(:value) { 'asc' }
      it { is_expected.to eq([3, 2, 1]) }
    end

    context "friends_desc is passed" do
      let(:value) { 'friends_desc' }
      it { is_expected.to eq([2, 3, 1]) }
    end

    context "friends_asc is passed" do
      let(:value) { 'friends_asc' }
      it { is_expected.to eq([1, 3, 2]) }
    end

    context "followers_desc is passed" do
      let(:value) { 'followers_desc' }
      it { is_expected.to eq([3, 1, 2]) }
    end

    context "followers_asc is passed" do
      let(:value) { 'followers_asc' }
      it { is_expected.to eq([2, 1, 3]) }
    end

    context "statuses_desc is passed" do
      let(:value) { 'statuses_desc' }
      it { is_expected.to eq([2, 1, 3]) }
    end

    context "statuses_asc is passed" do
      let(:value) { 'statuses_asc' }
      it { is_expected.to eq([3, 1, 2]) }
    end
  end
end
