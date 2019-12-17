require 'rails_helper'

RSpec.describe DeleteEgotterFollowerWorker do
  describe '#unique_key' do
    subject { described_class.new.unique_key(1) }
    it { is_expected.to eq(1) }
  end

  describe '#unique_in' do
    subject { described_class.new.unique_in }
    it { is_expected.to eq(1.minute) }
  end
end
