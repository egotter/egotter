require 'rails_helper'

RSpec.describe CreateTwitterUserTask, type: :model do
  let(:user) { create(:user) }
  let(:request) do
    CreateTwitterUserRequest.create(
        requested_by: 'test',
        session_id: 'session_id',
        user_id: user.id,
        uid: 1,
        ahoy_visit_id: 1)
  end
  let(:task) { CreateTwitterUserTask.new(request) }

  describe '#start!' do
    subject { task.start! }

    context 'request.perform! raises Twitter::Error::TooManyRequests' do
      before do
        Redis.client.flushdb
        allow(request).to receive(:perform!).with(no_args).and_raise(Twitter::Error::TooManyRequests)
      end

      it do
        expect { subject }.to raise_error(CreateTwitterUserRequest::TooManyRequests).
            and change { TooManyRequestsQueue.new.size }.by(1)
      end
    end
  end
end
