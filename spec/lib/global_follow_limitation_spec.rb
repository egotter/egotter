require 'rails_helper'

RSpec.describe GlobalFollowLimitation, type: :model do
  let(:instance) { described_class.new }

  before { Redis.new.flushall }

  describe '#limit_start' do
    subject { instance.limit_start }
    it { is_expected.to be_truthy }
  end

  describe '#limited?' do
    subject { instance.limited? }
    it { is_expected.to be_falsey }
  end
end
