require 'rails_helper'

RSpec.describe DeleteTweetsLog, type: :model do
  describe 'before_validation' do
    let(:log) { DeleteTweetsLog.new(error_message: 'a' * 180, message: 'b' * 180) }
    before { log.valid? }
    it 'truncates error_message' do
      expect(log.error_message.size).to eq(150)
    end
    it 'truncates message' do
      expect(log.error_message.size).to eq(150)
    end
  end

  describe '.create_by' do
    let(:user) { create(:user) }
    let(:request) { DeleteTweetsRequest.create(session_id: 's', user_id: user.id) }
    it do
      expect { DeleteTweetsLog.create_by(request: request) }.to change { DeleteTweetsLog.all.size }.by(1)
    end
  end
end
