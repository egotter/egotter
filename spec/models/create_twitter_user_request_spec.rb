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
    before do
      allow(request).to receive(:fetch_user).with(no_args).and_raise(Twitter::Error::Unauthorized, 'Invalid or expired token.')
    end

    it { expect { subject }.to raise_error(described_class::Unauthorized) }
  end

  describe '#fetch_user' do
    subject { request.fetch_user }
    before do
      allow(client).to receive(:user).with(1).and_raise(Twitter::Error::Unauthorized, 'Invalid or expired token.')
    end

    it { expect { subject }.to raise_error(described_class::Unauthorized) }
  end
end
