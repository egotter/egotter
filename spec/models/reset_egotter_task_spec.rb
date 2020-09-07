require 'rails_helper'

RSpec.describe ResetEgotterTask, type: :model do
  let(:user) { create(:user) }
  let(:request) { ResetEgotterRequest.create!(session_id: '-1', user_id: user.id) }
  let(:task) { described_class.new(request) }

  before do
    allow(task).to receive(:send_message_to_slack).with(any_args)
  end

  describe '#start!' do
    subject { task.start! }

    it do
      expect(request).to receive(:perform!).with(send_dm: true)
      subject
    end
  end
end
