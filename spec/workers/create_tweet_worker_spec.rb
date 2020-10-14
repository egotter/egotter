require 'rails_helper'

RSpec.describe CreateTweetWorker do
  let(:user) { create(:user) }
  let(:request) { TweetRequest.create(user_id: user.id, text: 'text') }

  before do
    allow(TweetRequest).to receive(:find).with(request.id).and_return(request)
  end

  describe '#perform' do
    subject { described_class.new.perform(request.id) }
    it do
      expect(request).to receive(:perform!)
      expect(request).to receive(:finished!)
      expect(ConfirmTweetWorker).to receive(:perform_async).with(request.id, confirm_count: 0)
      subject
    end
  end
end
