require 'rails_helper'

RSpec.describe DeleteTweetsWorker do
  let(:user) { create(:user) }
  let(:request) { create(:delete_tweets_request, user_id: user.id) }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(request.id) }
    before { allow(DeleteTweetsRequest).to receive(:find).with(request.id).and_return(request) }
    it do
      expect(DeleteTweetsTask).to receive_message_chain(:new, :start!).with(request, {}).with(no_args)
      subject
    end
  end
end
