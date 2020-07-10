require 'rails_helper'

RSpec.describe SendDeleteTweetsNotFinishedWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user) { create(:user) }
    let(:request) { DeleteTweetsRequest.create!(session_id: 'session_id', user_id: user.id) }
    subject { worker.perform(request.id) }
    it do
      expect(SlackClient).to receive_message_chain(:delete_tweets, :send_message).with(instance_of(String))
      subject
    end
  end
end
