require 'rails_helper'

RSpec.describe SendDeleteTweetsNotFinishedWorker do
  let(:user) { create(:user) }
  let(:request) { DeleteTweetsRequest.create!(user_id: user.id) }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(request.id) }
    it do
      expect(SendMessageToSlackWorker).to receive(:perform_async).with(any_args)
      subject
    end
  end
end
