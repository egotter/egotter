require 'rails_helper'

RSpec.describe DeleteFavoriteWorker do
  let(:user) { create(:user) }
  let(:request) { create(:delete_favorites_request, user_id: user.id) }
  let(:client) { double('client') }
  let(:tweet_id) { 1 }
  let(:worker) { described_class.new }

  before do
    allow(User).to receive(:find).with(user.id).and_return(user)
    allow(DeleteFavoritesRequest).to receive(:find).with(request.id).and_return(request)
    allow(user).to receive_message_chain(:api_client, :twitter).and_return(client)
  end

  describe '#perform' do
    subject { worker.perform(user.id, tweet_id, 'request_id' => request.id) }
    it do
      expect(worker).to receive(:destroy_favorite!).with(client, tweet_id, request).and_return('result')
      expect(request).to receive(:increment!).with(:destroy_count)
      subject
    end

    context 'retryable error is raised' do
      let(:error) { RuntimeError.new('error') }
      before { allow(worker).to receive(:destroy_favorite!).and_raise(error) }

      before { allow(TwitterApiStatus).to receive(:retry_timeout?).with(error).and_return(true) }
      it do
        expect(described_class).to receive(:perform_in).with(instance_of(Integer), user.id, tweet_id, 'request_id' => request.id, 'retries' => 1)
        subject
      end
    end
  end

  describe '#destroy_favorite!' do
    subject { worker.send(:destroy_favorite!, client, tweet_id, request) }

    context 'deletion succeeded' do
      it do
        expect(client).to receive(:unfavorite!).with(tweet_id)
        subject
      end
    end

    context 'error raised' do
      let(:error) { RuntimeError.new('error') }
      before { allow(client).to receive(:unfavorite!).and_raise(error) }

      context 'the error can be ignored' do
        before { allow(TweetStatus).to receive(:no_status_found?).with(error).and_return(true) }
        it { is_expected.to be_nil }
      end

      context 'the error cannot be ignored' do
        before { allow(TwitterApiStatus).to receive(:your_account_suspended?).with(error).and_return(true) }
        it do
          is_expected.to be_nil
          expect(request.reload.stopped_at).to be_truthy
        end
      end
    end
  end
end
