require 'rails_helper'

RSpec.describe Efs do
  describe '.enabled?' do
    it { expect(described_class.enabled?).to be_truthy }
  end
end
