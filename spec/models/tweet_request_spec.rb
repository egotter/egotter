require 'rails_helper'

RSpec.describe TweetRequest, type: :model do
  context 'validation' do
    let(:user) { create(:user) }
    let(:request) { TweetRequest.new(user_id: user.id) }

    context 'With https://egotter.com' do
      it 'saves' do
        request.text = 'Hello. https://egotter.com'
        expect(request.valid?).to be_truthy
      end
    end

    context 'With line breaks' do
      it 'saves' do
        request.text = "@user Hello. \n https://egotter.com"
        expect(request.valid?).to be_truthy

        request.text = "https://egotter.com\nGreat!"
        expect(request.valid?).to be_truthy
      end
    end

    context 'Without https://egotter.com' do
      it 'does not save' do
        request.text = 'Hello.'
        expect(request.valid?).to be_falsey
      end
    end
  end
end
