require 'rails_helper'

RSpec.describe ResetEgotterWorker do
  describe '#after_timeout' do
    let(:args) { [1, {}] }
    let(:retry_in) { 1.second }
    let(:worker) { described_class.new }
    before { allow(worker).to receive(:retry_in).and_return(retry_in) }
    it do
      expect(described_class).to receive(:perform_in).with(retry_in, *args)
      worker.after_timeout(*args)
    end
  end

  describe '#retry_in' do
    let(:worker) { described_class.new }
    it { expect(worker.retry_in).to be > worker.unique_in }
  end
end
