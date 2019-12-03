require 'rails_helper'

RSpec.describe DeleteTweetsRequest, type: :model do
  describe '#perform!' do

  end

  describe '#error_check!' do
    let(:user) { create(:user, authorized: authorized) }
    let(:request) { DeleteTweetsRequest.create(session_id: -1, user: user) }
    let(:subject) { request.error_check! }

    context 'authorized == false' do
      let(:authorized) { false }
      it { expect { subject }.to raise_error(DeleteTweetsRequest::Unauthorized) }
    end

    context 'The #verify_credentials raises an error' do
      let(:authorized) { true }

      before do
        client = double('Client')
        allow(user).to receive_message_chain(:api_client, :twitter).with(no_args).with(no_args).and_return(client)
        allow(client).to receive(:verify_credentials).with(no_args).and_raise('Invalid or expired token.')
      end

      it { expect { subject }.to raise_error(DeleteTweetsRequest::InvalidToken) }
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
end
