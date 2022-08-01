require 'rails_helper'

RSpec.describe SendDeleteTweetsFinishedMessageWorker do
  let(:user) { create(:user, authorized: true) }
  let(:request) { DeleteTweetsRequest.create(user: user, tweet: true, send_dm: true) }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(request.id) }
    before { allow(DeleteTweetsRequest).to receive(:find).and_return(request) }
    it do
      expect(request).to receive(:tweet_finished_message)
      expect(request).to receive(:send_finished_message)
      subject
    end

    context 'send_dm is false and destroy_count is 0' do
      before { request.update(send_dm: false, destroy_count: 0, reservations_count: 10) }
      it do
        expect(request).to receive(:tweet_finished_message)
        expect(request).to receive(:send_finished_message)
        subject
      end
    end

    context 'send_dm is false and reservations_count' do
      before { request.update(send_dm: false, destroy_count: 10, reservations_count: 0) }
      it do
        expect(request).to receive(:tweet_finished_message)
        expect(request).to receive(:send_finished_message)
        subject
      end
    end
  end
end
