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
      expect(client).to receive(:destroy_status).with(tweets[0].id)
      expect(client).to receive(:destroy_status).with(tweets[1].id).and_raise('error')
      expect(client).to receive(:destroy_status).with(tweets[2].id)
      subject
      expect(instance.reload.deletions_count).to eq(2)
    end
  end

  describe '#stop_processing?' do
    subject { instance.send(:stop_processing?, 10, 5) }
    it { is_expected.to be_falsey }
  end
end
