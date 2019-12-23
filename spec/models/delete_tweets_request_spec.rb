require 'rails_helper'

RSpec.describe DeleteTweetsRequest, type: :model do
  describe '#perform!' do
    let(:user) { create(:user, authorized: true) }
    let(:request) { DeleteTweetsRequest.create(session_id: -1, user: user) }
    let(:subject) { request.perform! }

    before do
      allow(request).to receive(:error_check!).with(no_args)
      allow(request).to receive(:api_client).and_raise('xxx Connection reset by peer xxx')
    end

    it { expect { subject }.to raise_error(described_class::RetryExhausted) }
  end

  describe '#error_check!' do
    let(:user) { create(:user, authorized: authorized) }
    let(:request) { DeleteTweetsRequest.create(session_id: -1, user: user) }
    let(:subject) { request.error_check! }

    context 'authorized == false' do
      let(:authorized) { false }
      it { expect { subject }.to raise_error(DeleteTweetsRequest::Unauthorized) }
    end

    context 'The #verify_credentials raises an error with "Invalid or expired token."' do
      let(:authorized) { true }

      before do
        client = double('Client')
        allow(user).to receive_message_chain(:api_client, :twitter).with(no_args).with(no_args).and_return(client)
        allow(client).to receive(:verify_credentials).with(no_args).and_raise(Twitter::Error::Unauthorized.new('Invalid or expired token.'))
      end

      it { expect { subject }.to raise_error(Twitter::Error::Unauthorized) }
    end

    context 'The #verify_credentials raises Twitter::Error::TooManyRequests' do
      let(:authorized) { true }

      before do
        client = double('Client')
        allow(user).to receive_message_chain(:api_client, :twitter).with(no_args).with(no_args).and_return(client)
        allow(client).to receive(:verify_credentials).with(no_args).and_raise(Twitter::Error::TooManyRequests)
      end

      it { expect { subject }.to raise_error(Twitter::Error::TooManyRequests) }
    end

    context 'statuses_count == 0' do
      let(:authorized) { true }

      before do
        client = double('Client', verify_credentials: nil, user: {statuses_count: 0})
        allow(user).to receive_message_chain(:api_client, :twitter).with(no_args).with(no_args).and_return(client)
      end

      it { expect { subject }.to raise_error(DeleteTweetsRequest::TweetsNotFound) }
    end
  end

  describe '#exception_handler' do
    let(:user) { create(:user) }
    let(:request) { DeleteTweetsRequest.create(session_id: -1, user: user) }
    let(:subject) { request.exception_handler(exception, 99) }

    context 'exception.is_a?(DeleteTweetsRequest::Error) == true' do
      let(:exception) { DeleteTweetsRequest::InvalidToken.new }
      it { expect { subject }.to raise_error(DeleteTweetsRequest::Unknown) }
    end
  end
end
