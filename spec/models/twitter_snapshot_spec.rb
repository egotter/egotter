require 'rails_helper'

RSpec.describe TwitterSnapshot do
  let(:user) do
    {id: 1, screen_name: 'name', friends_count: 100, followers_count: 200, protected: true}
  end
  let(:instance) { described_class.new(user) }

  describe '#uid' do
    subject { instance.uid }
    it { is_expected.to eq(user[:id]) }
  end

  describe '#screen_name' do
    subject { instance.screen_name }
    it { is_expected.to eq(user[:screen_name]) }
  end

  describe '#friends_count' do
    subject { instance.friends_count }
    it { is_expected.to eq(user[:friends_count]) }
  end

  describe '#followers_count' do
    subject { instance.followers_count }
    it { is_expected.to eq(user[:followers_count]) }
  end

  describe '#friend_uids=' do
    subject { instance.friend_uids = [1, 2, 3] }
    it { is_expected.to eq([1, 2, 3]) }
  end

  describe '#friends_size' do
    subject { instance.friends_size }
    before { instance.friend_uids = [1, 2, 3] }
    it { is_expected.to eq(3) }
  end

  describe '#follower_uids=' do
    subject { instance.follower_uids = [1, 2, 3] }
    it { is_expected.to eq([1, 2, 3]) }
  end

  describe '#followers_size' do
    subject { instance.followers_size }
    before { instance.follower_uids = [1, 2, 3] }
    it { is_expected.to eq(3) }
  end

  describe '#protected?' do
    subject { instance.protected? }
    it { is_expected.to be_truthy }
  end

  describe '#[]' do
    subject { instance[key] }

    before do
      instance.friend_uids = [1]
      instance.follower_uids = [2]
    end

    %i(friends_count followers_count friend_uids follower_uids).each do |key_value|
      context "key is #{key_value}" do
        let(:key) { key_value }
        it { is_expected.to be_truthy }
      end
    end

    %i(friends_size followers_size).each do |key_value|
      context "key is #{key_value}" do
        let(:key) { key_value }
        it { expect { subject }.to raise_error(RuntimeError) }
      end
    end
  end

  describe '#profile_text' do
    subject { instance.profile_text }
    it { is_expected.to be_truthy }
  end

  describe '#too_little_friends?' do
    subject { instance.too_little_friends? }
    it { is_expected.to be_falsey }
  end
end
