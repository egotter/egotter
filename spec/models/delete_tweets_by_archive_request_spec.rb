require 'rails_helper'

RSpec.describe DeleteTweetsByArchiveRequest, type: :model do
  let(:user) { create(:user) }
  let(:instance) { create(:delete_tweets_by_archive_request, user: user) }

  describe '#perform' do
    let(:tweets) { 'tweets' }
    let(:twitter) { 'twitter' }
    let(:client) { double('client', twitter: twitter) }
    subject { instance.perform(tweets) }
    before { allow(user).to receive(:api_client).and_return(client) }
    it do
      expect(instance).to receive(:delete_tweets).with(twitter, tweets)
      subject
    end
  end

  describe '#delete_tweets' do
    let(:tweets) { ['tweet1', 'tweet2'] }
    let(:client) { double('client') }
    subject { instance.send(:delete_tweets, client, tweets) }
    it do
      tweets.each do |tweet|
        expect(instance).to receive(:delete_tweet).with(client, tweet)
      end
      subject
      expect(instance.reload.deletions_count).to eq(tweets.size)
    end
  end

  describe '#delete_tweet' do
    let(:client) { double('client') }
    let(:tweet) { double('tweet', id: 1) }
    subject { instance.send(:delete_tweet, client, tweet) }
    it do
      expect(DeleteTweetWorker).to receive_message_chain(:new, :destroy_status!).with(client, tweet.id)
      subject
    end
  end
end
