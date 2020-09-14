require 'rails_helper'

RSpec.describe SlackClient, type: :model do
  describe '.monitoring' do
    subject { described_class.monitoring }
    it { is_expected.to be_truthy }
  end
end
