require 'rails_helper'

RSpec.describe ResetEgotterTask, type: :model do
  let(:user) { create(:user) }
  let(:request) { ResetEgotterRequest.create!(session_id: '-1', user_id: user.id) }
  let(:task) { described_class.new(request) }

  describe '#start!' do
    subject { task.start! }

    it do
      expect(request).to receive(:perform!).with(send_dm: true)
      allow(SendResetEgotterFinishedWorker).to receive(:perform_async).with(request.id)
      subject
    end
  end
end
