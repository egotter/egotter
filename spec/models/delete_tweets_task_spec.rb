require 'rails_helper'

RSpec.describe DeleteTweetsTask, type: :model do
  let(:user) { create(:user) }
  let(:request) { DeleteTweetsRequest.create!(session_id: '-1', user_id: user.id, tweet: false) }
  let(:task) { described_class.new(request) }

  describe '#start!' do
    subject { task.start! }

    context 'request.perform! raises RuntimeError(Anything)' do
      before do
        allow(request).to receive(:perform!).and_raise('Anything')
      end

      it do
        expect(request).to receive(:send_error_message)
        expect { subject }.to raise_error('Anything')
      end
    end
  end

  describe '#perform_request!' do
    subject { task.perform_request! }
    it do
      expect(request).to receive(:perform!).and_raise
      subject
    end
  end
end
