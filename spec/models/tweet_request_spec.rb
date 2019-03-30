require 'rails_helper'

RSpec.describe TweetRequest, type: :model do
  context 'validation' do
    let(:user) { create(:user) }
    let(:request) { TweetRequest.new(user_id: user.id) }
    it 'saves text with https://egotter.com' do
      request.text = 'Hello. https://egotter.com'
      expect(request.valid?).to be_truthy
    end

    it 'does not save text without https://egotter.com' do
      request.text = 'Hello.'
      expect(request.valid?).to be_falsey
    end
  end
end
