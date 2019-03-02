require 'rails_helper'

RSpec.describe UnfriendsBuilder do
end

RSpec.describe UnfriendsBuilder::Util do
  let(:older) { TwitterUser.new }
  let(:newer) { TwitterUser.new }

  before do
    allow(older).to receive(:friend_uids).with(no_args).and_return([1, 2, 3])
    allow(older).to receive(:follower_uids).with(no_args).and_return([4, 5, 6])

    if newer
      allow(newer).to receive(:friend_uids).with(no_args).and_return([2, 3, 4])
      allow(newer).to receive(:follower_uids).with(no_args).and_return([5, 6, 7])
    end
  end

  describe '.unfriends' do
    subject { described_class.unfriends(older, newer) }
    it { is_expected.to match_array([1]) }

    context 'newer.nil? == true' do
      let(:newer) { nil }
      it { is_expected.to be_nil }
    end
  end

  describe '.unfollowers' do
    subject { described_class.unfollowers(older, newer) }
    it { is_expected.to match_array([4]) }

    context 'newer.nil? == true' do
      let(:newer) { nil }
      it { is_expected.to be_nil }
    end
  end
end
