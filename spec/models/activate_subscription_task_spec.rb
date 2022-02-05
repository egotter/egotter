require 'rails_helper'

RSpec.describe ActivateSubscriptionTask, type: :model do
  let(:user) { create(:user) }
  let(:task) do
    described_class.new(
        screen_name: user.screen_name,
        months_count: 1,
        email: 'abc@example.com',
        price_id: 'pid',
    )
  end

  describe '#validate_task' do
    subject { task.send(:validate_task) }

    before do
      allow(User).to receive(:find_by).with(screen_name: user.screen_name).and_return(user)
    end

    it do
      expect(user).to receive_message_chain(:api_client, :twitter, :verify_credentials)
      expect(user).to receive(:has_valid_subscription?)
      subject
    end
  end
end
