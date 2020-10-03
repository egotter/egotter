require 'rails_helper'

RSpec.describe DeleteTweetsRequest, type: :model do
  let(:user) { create(:user, authorized: true) }
  let(:request) { DeleteTweetsRequest.create(user: user) }

  describe '#finished!' do
    subject { request.finished! }
    it do
      freeze_time do
        expect(request).to receive(:update!).with(finished_at: Time.zone.now)
        expect(request).not_to receive(:tweet_finished_message)
        expect(request).to receive(:send_finished_message)
        subject
      end
    end
  end

  describe '#perform!' do
    let(:subject) { request.perform! }

    it do
      expect(request).to receive(:verify_credentials!)
      expect(request).to receive(:tweets_exist!)
      expect(request).to receive(:fetch_statuses!).and_return('tweets')
      expect(request).to receive(:destroy_statuses!).with('tweets')
      subject
    end
  end

  describe '#verify_credentials!' do
    let(:subject) { request.verify_credentials! }
    before { request.instance_variable_set(:@retries, 1) }

    context 'user is authorized' do
      before { user.update(authorized: true) }
      it do
        expect(request).to receive_message_chain(:api_client, :verify_credentials)
        subject
      end
    end

    context 'user is not authorized' do
      before { user.update(authorized: false) }
      it { expect { subject }.to raise_error(described_class::Unauthorized) }
    end

    context 'Twitter::Error::TooManyRequests is raised' do
      before { allow(request).to receive_message_chain(:api_client, :verify_credentials).and_raise(Twitter::Error::TooManyRequests) }
      it do
        expect(request).not_to receive(:exception_handler)
        subject
      end
    end

    context 'exception is raised' do
      let(:error) { RuntimeError.new('error') }
      before { allow(request).to receive_message_chain(:api_client, :verify_credentials).and_raise(error) }
      it do
        expect(request).to receive(:exception_handler).with(error, :verify_credentials!)
        subject
      end
    end
  end

  describe '#tweets_exist!' do
    let(:user_response) { double('user_response', statuses_count: count) }
    let(:subject) { request.tweets_exist! }
    before { request.instance_variable_set(:@retries, 1) }

    before { allow(request).to receive_message_chain(:api_client, :user).with(user.uid).and_return(user_response) }

    context 'statuses_count is 0' do
      let(:count) { 0 }
      it { expect { subject }.to raise_error(described_class::TweetsNotFound) }
    end

    context 'statuses_count is not 0' do
      let(:count) { 100 }
      it { expect { subject }.not_to raise_error }
    end

    context 'exception is raised' do
      let(:count) { -1 }
      let(:error) { RuntimeError.new('error') }
      before { allow(request).to receive_message_chain(:api_client, :user).and_raise(error) }
      it do
        expect(request).to receive(:exception_handler).with(error, :tweets_exist!)
        subject
      end
    end
  end

  describe '#fetch_statuses!' do
    let(:tweets) do
      [double('tweet', id: 200, created_at: 1.day.ago), double('tweet', id: 100, created_at: 1.day.ago)]
    end
    subject { request.fetch_statuses! }

    before do
      allow(request).to receive_message_chain(:api_client, :user_timeline).
          with(count: 200).and_return(tweets)
      allow(request).to receive_message_chain(:api_client, :user_timeline).
          with(count: 200, max_id:  99).and_return([])
    end

    it { is_expected.to match_array(tweets) }

    context 'tweets is empty' do
      let(:tweets) { [] }
      it do
        expect { subject }.to raise_error(described_class::TweetsNotFound)
      end
    end
  end

  describe '#destroy_statuses!' do
    let(:tweets) do
      [double('tweet', id: 1), double('tweet', id: 2)]
    end
    subject { request.destroy_statuses!(tweets) }

    it do
      tweets.each do |tweet|
        expect(DeleteTweetWorker).to receive(:perform_async).with(user.id, tweet.id, request_id: request.id, last_tweet: tweet == tweets.last)
      end
      subject
    end
  end

  describe '#exception_handler' do
    subject { request.exception_handler(exception, :last_method) }

    context 'exception is a kind of Error' do
      let(:exception) { described_class::InvalidToken.new }
      it { expect { subject }.to raise_error(exception) }
    end

    context 'exception is Twitter::Error::TooManyRequests' do
      let(:exception) { Twitter::Error::TooManyRequests.new }
      it { expect { subject }.to raise_error(described_class::TooManyRequests) }
    end
  end
end

RSpec.describe DeleteTweetsRequest::Report, type: :model do
  let(:user) { create(:user, authorized: true) }
  let(:request) { DeleteTweetsRequest.create(user: user, destroy_count: 0) }

  describe '.finished_tweet' do
    subject { described_class.finished_tweet(user, request) }
    it { is_expected.to be_truthy }
  end

  describe '.finished_message' do
    subject { described_class.finished_message(user, request) }
    it { is_expected.to be_truthy }

    context 'destroy_count is 10' do
      before { request.update!(destroy_count: 10) }
      it { is_expected.to be_truthy }
    end
  end

  describe '.finished_message_from_user' do
    subject { described_class.finished_message_from_user(user) }
    it { is_expected.to be_truthy }
  end

  describe '.error_message' do
    subject { described_class.error_message(user) }
    it { is_expected.to be_truthy }
  end

  describe '.delete_tweets_url' do
    subject { described_class.delete_tweets_url('via') }
    it { is_expected.to be_truthy }
  end
end
