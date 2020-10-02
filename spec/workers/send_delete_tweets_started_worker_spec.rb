require 'rails_helper'

RSpec.describe SendDeleteTweetsStartedWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user) { create(:user) }
    let(:request) { DeleteTweetsRequest.create!(user_id: user.id) }
    subject { worker.perform(request.id) }
    it { is_expected.to be_truthy }
  end
end
