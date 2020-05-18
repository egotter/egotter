require 'rails_helper'

RSpec.describe DeleteTweetsRequest, type: :model do
  let(:user) { create(:user, authorized: true) }
  let(:request) { DeleteTweetsRequest.create(session_id: -1, user: user) }

  describe '#perform!' do
    let(:subject) { request.perform! }

    it do
      expect(request).to receive(:verify_credentials!)
      expect(request).to receive(:tweets_exist!)
      expect(request).to receive(:destroy_statuses!)
      expect { subject }.to raise_error(described_class::Continue)
    end
  end

  shared_examples 'it receives exception_handler with an exception' do
    let(:error) { RuntimeError.new('error') }
    before { allow(request).to receive(:api_client).and_raise(error) }
    it do
      expect(request).to receive(:exception_handler).with(error).and_call_original
      expect { subject }.to raise_error(described_class::Unknown)
    end
  end

  describe '#verify_credentials!' do
    let(:subject) { request.verify_credentials! }

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

    context 'exception is raised' do
      include_examples 'it receives exception_handler with an exception'
    end
  end

  describe '#tweets_exist!' do
    let(:user_response) { double('user_response', statuses_count: count) }
    let(:subject) { request.tweets_exist! }

    before { allow(request).to receive_message_chain(:api_client, :user).and_return(user_response) }

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
      include_examples 'it receives exception_handler with an exception'
    end
  end

  describe '#destroy_statuses!' do
    let(:tweets) do
      [
          double('tweet', id: 1, created_at: 1.day.ago),
          double('tweet', id: 2, created_at: 1.day.ago)
      ]
    end
    subject { request.destroy_statuses! }

    before do
      allow(request).to receive_message_chain(:api_client, :user_timeline).
          with(count: described_class::FETCH_COUNT).and_return(tweets)
    end
    it do
      tweets.each do |tweet|
        expect(request).to receive(:destroy_status!).with(tweet.id)
      end

      subject
    end
  end

  describe '#destroy_status!' do
    let(:tweet_id) { 1 }
    subject { request.destroy_status!(tweet_id) }
    it do
      expect(request).to receive_message_chain(:api_client, :destroy_status).with(tweet_id)
      subject
    end
  end

  describe '#exception_handler' do
    subject { request.exception_handler(exception) }

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

  describe '.finished_tweet' do
    subject { described_class.finished_tweet(user) }
    it { is_expected.to be_truthy }
  end

  describe '.finished_message' do
    subject { described_class.finished_message(user) }
    it { is_expected.to be_truthy }
  end

  describe '.finished_message_from_user' do
    subject { described_class.finished_message_from_user(user) }
    it { is_expected.to be_truthy }
  end

  describe '.error_message' do
    subject { described_class.error_message(user) }
    it { is_expected.to be_truthy }
  end
end
