require 'rails_helper'

RSpec.describe GlobalMessage, type: :model do
  describe '.message_found?' do
    it { expect(described_class.message_found?).to be_falsey }
  end
end
