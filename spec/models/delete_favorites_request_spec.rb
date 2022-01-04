require 'rails_helper'

RSpec.describe DeleteFavoritesRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) { described_class.create(user: user) }

  describe '#finished!' do
    subject { request.finished! }
    it do
      freeze_time do
        expect(request).to receive(:update!).with(finished_at: Time.zone.now)
        expect(request).not_to receive(:tweet_finished_message)
        expect(request).not_to receive(:send_finished_message)
        subject
      end
    end
  end

  describe '#perform!' do
    let(:subject) { request.perform! }

    it do
      expect(request).to receive(:verify_credentials!)
      expect(request).to receive(:favorites_exist!)
      expect(request).to receive(:fetch_favorites!).and_return('tweets')
      expect(request).to receive(:destroy_favorites!).with('tweets')
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

  describe '#favorites_exist!' do
    let(:user_response) { double('user_response', favourites_count: count) }
    let(:subject) { request.favorites_exist! }
    before { request.instance_variable_set(:@retries, 1) }

    before { allow(request).to receive_message_chain(:api_client, :user).with(user.uid).and_return(user_response) }

    context 'statuses_count is 0' do
      let(:count) { 0 }
      it { expect { subject }.to raise_error(described_class::FavoritesNotFound) }
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
        expect(request).to receive(:exception_handler).with(error, :favorites_exist!)
        subject
      end
    end
  end

  describe '#fetch_favorites!' do
    let(:tweets) do
      [double('tweet', id: 200, created_at: 1.day.ago), double('tweet', id: 100, created_at: 1.day.ago)]
    end
    subject { request.fetch_favorites! }

    before do
      allow(request).to receive_message_chain(:api_client, :favorites).
          with(count: 200).and_return(tweets)
      allow(request).to receive_message_chain(:api_client, :favorites).
          with(count: 200, max_id:  99).and_return([])
    end

    it { is_expected.to match_array(tweets) }

    context 'tweets is empty' do
      let(:tweets) { [] }
      it do
        expect { subject }.to raise_error(described_class::FavoritesNotFound)
      end
    end
  end

  describe '#destroy_favorites!' do
    let(:tweets) do
      [double('tweet', id: 1), double('tweet', id: 2)]
    end
    subject { request.destroy_favorites!(tweets) }

    it do
      tweets.each.with_index do |tweet, i|
        interval = (0.1 * i).floor
        expect(DeleteFavoriteWorker).to receive(:perform_in).with(interval, user.id, tweet.id, request_id: request.id, last_tweet: tweet == tweets.last)
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

  describe '#send_finished_message' do
    subject { request.send_finished_message }
    it do
      expect(request).to receive(:send_start_message)
      expect(request).to receive(:send_result_message)
      subject
    end
  end

  describe '#send_start_message' do
    subject { request.send_start_message }
    it do
      expect(DeleteFavoritesReport).to receive_message_chain(:finished_message_from_user, :deliver!).with(user).with(no_args)
      subject
    end
  end

  describe '#send_result_message' do
    subject { request.send_result_message }
    it do
      expect(DeleteFavoritesReport).to receive_message_chain(:finished_message, :deliver!).with(user, request).with(no_args)
      subject
    end
  end
end
