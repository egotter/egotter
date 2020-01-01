require 'rails_helper'

RSpec.describe CreateTwitterUserRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) do
    described_class.create(
        requested_by: 'test',
        session_id: 'session_id',
        user_id: user.id,
        uid: 1,
        ahoy_visit_id: 1)
  end
  let(:client) { double('Client') }

  before { allow(request).to receive(:client).with(no_args).and_return(client) }

  describe '#build_twitter_user' do
    subject { request.build_twitter_user }

    context 'The token is invalid' do
      before { allow(request).to receive(:fetch_user).and_raise(Twitter::Error::Unauthorized, 'Invalid or expired token.') }
      it { expect { subject }.to raise_error(described_class::Unauthorized) }
    end

    context 'The user is protected' do
      before { allow(request).to receive(:fetch_user).and_raise(Twitter::Error::Unauthorized, 'Not authorized.') }
      it { expect { subject }.to raise_error(described_class::Protected) }
    end

    context '#fetch_user raises Twitter::Error::InternalServerError' do
      before { allow(request).to receive(:fetch_user).and_raise(Twitter::Error::InternalServerError, 'Internal error') }
      it { expect { subject }.to raise_error(described_class::InternalServerError) }
    end

    context '#fetch_user raises Twitter::Error::ServiceUnavailable' do
      before { allow(request).to receive(:fetch_user).and_raise(Twitter::Error::ServiceUnavailable, 'Over capacity') }
      it { expect { subject }.to raise_error(described_class::ServiceUnavailable) }
    end

    context '#fetch_user raises Twitter::Error::Unauthorized(blocked)' do
      before { allow(request).to receive(:fetch_user).and_raise(Twitter::Error::Unauthorized, "You have been blocked from viewing this user's profile.") }
      it { expect { subject }.to raise_error(described_class::Blocked) }
    end
  end

  describe '#fetch_user' do
    subject { request.fetch_user }
    before do
      allow(client).to receive(:user).with(1).and_raise(Twitter::Error::Unauthorized, 'Invalid or expired token.')
    end

    it { expect { subject }.to raise_error(described_class::Unauthorized) }
  end
end
