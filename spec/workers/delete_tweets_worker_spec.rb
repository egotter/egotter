require 'rails_helper'

RSpec.describe DeleteTweetsWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user) { create(:user) }
    let(:request) { DeleteTweetsRequest.create!(session_id: 'session_id', user_id: user.id) }
    let(:task) { DeleteTweetsTask.new(request) }
    subject { worker.perform(request.id) }
    before { allow(DeleteTweetsTask).to receive(:new).with(request).and_return(task) }
    it do
      expect(task).to receive(:start!)
      subject
    end
  end
end
