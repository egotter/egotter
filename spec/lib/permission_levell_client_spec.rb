require 'rails_helper'

RSpec.describe PermissionLevelClient, type: :model do
  describe '#permission_level' do
    subject { described_class.new('client').permission_level }
    it do
      allow(described_class::Request).to receive_message_chain(:new, :perform).with(any_args).with(no_args).and_return('X-Access-Level' => 'value')
      is_expected.to eq('value')
    end
  end
end
