require 'rails_helper'

RSpec.describe ResetEgotterWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  describe '#retry_in' do
    it { expect(worker.retry_in).to be >= worker.unique_in }
  end

  describe '#perform' do
    let(:request) { ResetEgotterRequest.create!(user_id: user.id, session_id: 'sid') }
    subject { worker.perform(request.id) }
    it { is_expected.to be_truthy }
  end
end
