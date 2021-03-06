require 'rails_helper'

RSpec.describe DeleteForbiddenUsersWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform }
    before do
      create(:forbidden_user, created_at: 1.hour.ago)
      create(:forbidden_user, created_at: 2.hours.ago)
      create(:forbidden_user, created_at: 10.minutes.ago)
    end

    it { expect { subject }.to change { ForbiddenUser.all.size }.by(-2) }
  end
end
