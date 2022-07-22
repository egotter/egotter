require 'rails_helper'

RSpec.describe TwitterUserMultiplePeopleApi do
  let(:twitter_user) { create(:twitter_user, with_relations: true) }

  describe '#common_mutual_friend_uids' do
    let(:other) { create(:twitter_user, with_relations: true) }
    subject { twitter_user.common_mutual_friend_uids(other) }
    it do
      expect(twitter_user).to receive(:mutual_friend_uids).and_return([1, 2, 3])
      expect(other).to receive(:mutual_friend_uids).and_return([2, 3, 4])
      is_expected.to eq([2, 3])
    end
  end

  describe '#common_mutual_friends' do
    let(:uids) { [1, 2, 3] }
    let(:other) { double('twitter_user') }
    subject { twitter_user.common_mutual_friends(other) }
    before { uids.map { |uid| create(:twitter_db_user, uid: uid) } }
    it do
      expect(twitter_user).to receive(:common_mutual_friend_uids).with(other).and_return(uids)
      expect(subject.map(&:uid)).to eq(uids)
    end
  end
end
