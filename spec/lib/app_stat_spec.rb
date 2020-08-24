require 'rails_helper'

RSpec.describe AppStat, type: :model do
  let(:instance) { described_class.new }

  describe '#to_s' do
    subject { described_class.new }
    it { is_expected.to be_truthy }
  end
end
