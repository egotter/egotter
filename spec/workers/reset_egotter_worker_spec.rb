require 'rails_helper'

RSpec.describe ResetEgotterWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  describe '#after_timeout' do
    let(:args) { [1, {}] }
    let(:retry_in) { 1.second }
    before { allow(worker).to receive(:retry_in).and_return(retry_in) }
    it do
      expect(described_class).to receive(:perform_in).with(retry_in, *args)
      worker.after_timeout(*args)
    end
  end

  describe '#retry_in' do
    it { expect(worker.retry_in).to be >= worker.unique_in }
  end

  describe '#perform' do
    let(:request) { ResetEgotterRequest.create!(user_id: user.id, session_id: 'sid') }
    subject { worker.perform(request.id) }
    it { is_expected.to be_truthy }
  end
end
