require 'rails_helper'

RSpec.describe CreateViolationEventWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(user.id, 'Test') }
    it do
      subject
      expect(ViolationEvent.where(user_id: user.id).exists?).to be_truthy
      expect(BannedUser.where(user_id: user.id).exists?).to be_truthy
    end
  end
end
