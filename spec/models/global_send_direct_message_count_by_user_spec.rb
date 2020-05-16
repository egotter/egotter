require 'rails_helper'

RSpec.describe GlobalSendDirectMessageCountByUser do
  let(:instance) { described_class.new }
  let(:uid) { 1 }

  before { Redis.client.flushdb }

  describe '#increment' do
    subject { instance.increment(uid) }
    it { expect { subject }.to change { described_class.new.count(uid) }.from(0).to(1) }
  end

  describe '#clear' do
    subject { instance.clear(uid) }
    before { instance.increment(uid) }
    it { expect { subject }.to change { described_class.new.count(uid) }.from(1).to(0) }
  end

  describe '#count' do
    subject { instance.count(uid) }
    it do
      is_expected.to eq(0)
      instance.increment(uid)
      expect(instance.count(uid)).to eq(1)
    end
  end
end
