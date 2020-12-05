require 'rails_helper'

RSpec.describe CloudWatchClient, type: :model do
end

RSpec.describe CloudWatchClient::Dashboard, type: :model do
  describe '#logger' do
    it { expect(described_class.new('name').respond_to?(:logger)).to be_truthy }
  end
end
