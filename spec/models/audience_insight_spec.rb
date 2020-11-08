require 'rails_helper'

RSpec.describe AudienceInsight do
end

RSpec.describe AudienceInsight::Builder do
  describe '#build' do
    let(:twitter_user) { create(:twitter_user) }
    subject { described_class.new(twitter_user.uid).build }
    before do
      allow(TwitterUser).to receive_message_chain(:latest_by, :status_tweets).
          with(uid: twitter_user.uid).with(no_args).and_return([])

      cache = InMemory::TwitterUser.new(friend_uids: [1], follower_uids: [2])
      allow(InMemory::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(cache)
    end
    it { is_expected.to be_truthy }
  end
end
