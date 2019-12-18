require 'rails_helper'

RSpec.describe UpdateAuthorizedWorker do
  let(:worker) { described_class.new }

  describe '#unique_key' do
    it { expect(worker.unique_key(1)).to eq(1) }
  end

  describe '#unique_in' do
    it { expect(worker.unique_in).to eq(1.minute) }
  end

  describe '#expire_in' do
    it { expect(worker.expire_in).to eq(1.minute) }
  end

  describe '#timeout_in' do
    it { expect(worker.timeout_in).to eq(5.seconds) }
  end

  describe '#after_timeout' do
    let(:args) { [1, {}] }
    let(:retry_in) { 1.second }
    before { allow(worker).to receive(:retry_in).and_return(retry_in) }
    it do
      expect(described_class).to receive(:perform_in).with(worker.retry_in, *args)
      worker.after_timeout(*args)
    end
  end

  describe '#retry_in' do
    it { expect(worker.retry_in).to be > worker.unique_in }
  end
end
