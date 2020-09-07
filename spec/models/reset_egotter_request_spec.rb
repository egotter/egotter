require 'rails_helper'

RSpec.describe ResetEgotterRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) { described_class.create!(session_id: '-1', user_id: user.id) }

  describe '#perform!' do
    subject { request.perform! }

    context '#finished? returns true' do
      before { allow(request).to receive(:finished?).and_return(true) }
      it { expect { subject }.to raise_error(described_class::AlreadyFinished) }
    end

    context 'twitter_user not found' do
      it { expect { subject }.to raise_error(described_class::TwitterUserNotFound) }
    end
  end
end
