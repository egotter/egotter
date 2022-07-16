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
    let(:tweets) { 100.times.map { |i| double("tweet#{i}", id: i) } }
    let(:client) { double('client') }
    subject { instance.send(:delete_tweets, client, tweets, 4) }
    before { instance.update(reservations_count: tweets.size, started_at: Time.zone.now) }
    it do
      tweets.each.with_index do |tweet, i|
        if i % 10 == 0
          expect(client).to receive(:destroy_status).with(tweets[i].id).and_raise('error')
        else
          expect(client).to receive(:destroy_status).with(tweets[i].id)
        end
      end
      subject
      instance.reload
      expect(instance.deletions_count).to eq(90)
      expect(instance.errors_count).to eq(10)
    end
  end
end
