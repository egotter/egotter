require 'rails_helper'

RSpec.describe UpdateAudienceInsightWorker do
  let(:worker) { described_class.new }

  describe '#retry_in' do
    subject { worker.retry_in }
    it { is_expected.to be >= worker.unique_in }
  end

  describe '#perform' do
    let(:error) { RuntimeError }
    subject { worker.perform('uid', 'options') }

    before { allow(AudienceInsight).to receive(:find_or_initialize_by).with(any_args).and_raise(error) }

    it do
      expect(worker).to receive(:handle_exception).with(error, 'uid', 'options')
      subject
    end
  end
end
