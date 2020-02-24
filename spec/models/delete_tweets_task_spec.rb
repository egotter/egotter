require 'rails_helper'

RSpec.describe DeleteTweetsTask, type: :model do
  let(:user) { create(:user) }
  let(:request) do
    DeleteTweetsRequest.create!(
        session_id: '-1',
        user_id: user.id,
        tweet: false)
  end
  let(:task) { DeleteTweetsTask.new(request) }

  before do
    allow(task).to receive(:send_message_to_slack)
  end

  describe '#start!' do
    subject { task.start! }

    context 'request.perform! raises RuntimeError(Anything)' do
      before do
        allow(request).to receive(:perform!).with(no_args).and_raise('Anything')
      end

      it do
        expect(request).to receive(:send_error_message)
        expect { subject }.to raise_error('Anything')
      end
    end
  end
end
