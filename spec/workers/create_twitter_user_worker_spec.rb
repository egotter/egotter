require 'rails_helper'

RSpec.describe CreateTwitterUserWorker do
  describe '#unique_key' do
    let(:request) { create(:create_twitter_user_request) }
    let(:worker) { described_class.new }
    subject { worker.unique_key(request.id, {}) }
    it do
      is_expected.to eq("#{request.user_id}-#{request.uid}")
    end
  end
end
