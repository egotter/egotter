require 'rails_helper'

RSpec.describe DeleteTweetWorker do
  let(:user) { create(:user) }
  let(:request) { create(:delete_tweets_request, user_id: user.id) }
  let(:client) { double('client') }
  let(:tweet_id) { 1 }
  let(:worker) { described_class.new }

  before do
    allow(User).to receive(:find).with(user.id).and_return(user)
    allow(DeleteTweetsRequest).to receive(:find).with(request.id).and_return(request)
    allow(user).to receive_message_chain(:api_client, :twitter).and_return(client)
  end

  describe '#perform' do
    subject { worker.perform(user.id, tweet_id, 'request_id' => request.id) }
    it do
      expect(worker).to receive(:destroy_status!).with(client, tweet_id).and_return('result')
      expect(request).to receive(:increment!).with(:destroy_count)
      subject
    end
  end

  describe '#destroy_status!' do
    subject { worker.send(:destroy_status!, client, tweet_id) }
    it do
      expect(client).to receive(:destroy_status).with(tweet_id)
      subject
    end

    context 'If the number of retries is too many' do
      before do
        allow(client).to receive(:destroy_status).with(any_args).and_raise('Error')
        allow(ServiceStatus).to receive(:retryable_error?).with(any_args).and_return(true)
      end
      it { expect { subject }.to raise_error(described_class::RetryExhausted) }
    end
  end
end
