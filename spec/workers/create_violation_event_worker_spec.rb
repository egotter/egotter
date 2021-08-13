require 'rails_helper'

RSpec.describe CreateViolationEventWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(user.id, 'Test', 'text' => 'Text') }
    it do
      expect(worker).to receive(:create_event).with(user.id, 'Test', 'Text')
      expect(BannedUser).to receive(:create).with(user_id: user.id)
      subject
    end
  end

  describe '#create_event' do
    subject { worker.send(:create_event, user.id, 'Test', 'Text') }
    it do
      subject
      expect(ViolationEvent.where(user_id: user.id).exists?).to be_truthy
    end
  end
end
