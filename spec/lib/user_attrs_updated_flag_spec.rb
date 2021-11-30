require 'rails_helper'

RSpec.describe UserAttrsUpdatedFlag, type: :model do
  let(:user_id) { 1 }

  before { Redis.client.flushall }

  describe '.on' do
    subject { described_class.on(user_id) }
    it do
      described_class.on(user_id)
      expect(described_class.on?(user_id)).to be_truthy
    end
  end

  describe '.on?' do
    subject { described_class.on?(user_id) }
    it do
      described_class.on(user_id)
      expect(subject).to be_truthy
    end
  end

  describe '.key' do
    subject { described_class.key(user_id) }
    it { is_expected.to eq("test:UserAttrsUpdatedFlag:#{user_id}") }
  end
end
