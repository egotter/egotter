require 'rails_helper'

RSpec.describe CreateDeletableTweetsRequest, type: :model do
  let(:user) { create(:user) }
  let(:instance) { create(:create_deletable_tweets_request, user: user) }

  describe '#perform' do
    let(:tweet_attrs) { {id: 1} }
    let(:tweets_resp) { [double('tweet_resp', attrs: tweet_attrs)] }
    let(:tweets) { [double('tweet')] }
    subject { instance.perform }
    before do
      allow(instance).to receive(:collect_tweets_with_max_id).and_yield(tweets_resp)
    end
    it do
      expect(DeletableTweet).to receive(:from_array).with([tweet_attrs]).and_return(tweets)
      expect(instance).to receive(:save_tweets).with(tweets)
      subject
    end
  end

  describe '#save_tweets' do
    let(:tweets) do
      [
          build(:deletable_tweet, uid: user.uid, tweet_id: 1),
          build(:deletable_tweet, uid: user.uid, tweet_id: 2),
      ]
    end
    subject { instance.send(:save_tweets, tweets) }

    it { expect { subject }.to change { DeletableTweet.all.size }.by(2) }

    context 'A tweet has already been persisted' do
      before { tweets[0].save! }
      it { expect { subject }.to change { DeletableTweet.all.size }.by(1) }
    end
  end
end
