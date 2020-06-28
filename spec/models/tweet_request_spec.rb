require 'rails_helper'

RSpec.describe TweetRequest, type: :model do
  let(:user) { create(:user) }

  context 'validation' do
    let(:request) { TweetRequest.new(user_id: user.id, text: text) }
    subject { request.valid? }

    [
        'Hello. https://egotter.com',
        "@user Hello. \n https://egotter.com",
        "https://egotter.com\nGreat!",
        'hello https://egotter.com/' + 'a' * 200,
    ].each do |str|
      context "text is #{str}" do
        let(:text) { str }
        it { is_expected.to be_truthy }
      end
    end

    # [
    #     'Hello.',
    # ].each do |str|
    #   context "text is #{str}" do
    #     let(:text) { str }
    #     it { is_expected.to be_falsey }
    #   end
    # end
  end
end
