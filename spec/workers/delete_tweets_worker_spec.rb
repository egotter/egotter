require 'rails_helper'

RSpec.describe DeleteTweetsWorker do
  let(:user) { create(:user) }
  let(:request) { create(:delete_tweets_request, user_id: user.id) }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(request.id) }
    before { allow(DeleteTweetsRequest).to receive(:find).with(request.id).and_return(request) }
    it do
      expect(request).to receive(:perform)
      subject
    end
  end
end
