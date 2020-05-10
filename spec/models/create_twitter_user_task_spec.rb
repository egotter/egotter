require 'rails_helper'

RSpec.describe CreateTwitterUserTask, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:create_twitter_user_request, user_id: user.id, uid: 1) }
  let(:task) { CreateTwitterUserTask.new(request) }

  describe '#start!' do
    let(:context) { 'context' }
    subject { task.start!(context) }

    context 'request.perform! raises Twitter::Error::TooManyRequests' do
      before do
        Redis.client.flushdb
        allow(request).to receive(:perform!).with(context).and_raise(Twitter::Error::TooManyRequests)
      end

      it do
        expect { subject }.to raise_error(CreateTwitterUserRequest::TooManyRequests).
            and change { TooManyRequestsUsers.new.size }.by(1)
      end
    end
  end
end
