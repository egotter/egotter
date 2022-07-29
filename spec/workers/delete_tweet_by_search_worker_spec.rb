require 'rails_helper'

RSpec.describe DeleteTweetBySearchWorker do
  let(:user) { create(:user) }
  let(:request) { create(:delete_tweets_by_search_request, user_id: user.id) }
  let(:tweet) { create(:deletable_tweet, uid: user.uid, tweet_id: 1, deletion_reserved_at: Time.zone.now) }
  let(:client) { double('client') }
  let(:worker) { described_class.new }

  before do
    allow(DeleteTweetsBySearchRequest).to receive(:find).with(request.id).and_return(request)
    allow(request).to receive(:user).and_return(user)
  end

  describe '#perform' do
    subject { worker.perform(request.id, tweet.tweet_id) }
    it do
      expect(worker).to receive(:destroy_status).with(tweet, request)
      subject
    end
  end

  describe '#destroy_status' do
    subject { worker.send(:destroy_status, tweet, request) }

    context 'deletion succeeded' do
      it do
        expect(tweet).to receive(:delete_tweet!)
        expect(request).to receive(:increment!).with(:deletions_count)
        subject
      end
    end

    context 'error is raised' do
      let(:error) { RuntimeError.new('error') }
      let(:error_handler) { DeleteTweetWorker::ErrorHandler.new(nil) }
      before do
        allow(tweet).to receive(:delete_tweet!).and_raise(error)
        allow(DeleteTweetWorker::ErrorHandler).to receive(:new).with(error).and_return(error_handler)
      end

      it do
        expect(request).not_to receive(:increment!).with(:deletions_count)
        expect(request).to receive(:update).with(error_message: error.inspect)
        expect(request).to receive(:increment!).with(:errors_count)
        expect(error_handler).to receive(:raise?).and_return(true)
        expect { subject }.to raise_error(error)
      end
    end
  end
end
