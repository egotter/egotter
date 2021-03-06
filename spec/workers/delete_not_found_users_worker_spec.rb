require 'rails_helper'

RSpec.describe DeleteNotFoundUsersWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform }
    before do
      create(:not_found_user, created_at: 1.hour.ago)
      create(:not_found_user, created_at: 2.hours.ago)
      create(:not_found_user, created_at: 10.minutes.ago)
    end

    it { expect { subject }.to change { NotFoundUser.all.size }.by(-2) }
  end
end
