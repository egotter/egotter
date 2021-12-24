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
      expect(instance).to receive(:delete_tweets).with(twitter, tweets, 4)
      subject
    end
  end

  describe '#delete_tweets' do
    let(:tweets) { [double('tweet1', id: 1), double('tweet2', id: 2), double('tweet2', id: 3)] }
    let(:client) { double('client') }
    subject { instance.send(:delete_tweets, client, tweets, 1) }
    it do
      tweets.each do |tweet|
        expect(client).to receive(:destroy_status).with(tweet.id)
      end
      subject
      expect(instance.reload.deletions_count).to eq(tweets.size)
    end
  end
end
