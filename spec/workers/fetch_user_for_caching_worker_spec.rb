require 'rails_helper'

RSpec.describe FetchUserForCachingWorker do
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
end
