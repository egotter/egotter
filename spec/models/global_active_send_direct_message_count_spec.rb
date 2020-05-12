require 'rails_helper'

RSpec.describe GlobalActiveSendDirectMessageCount, type: :model do
  describe '#increment' do
    subject { described_class.new.increment }
    it { expect { subject }.to change { described_class.new.size }.by(1) }
  end
end
