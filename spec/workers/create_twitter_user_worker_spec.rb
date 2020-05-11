require 'rails_helper'

RSpec.describe CreateTwitterUserWorker do
  let(:request) { create(:create_twitter_user_request) }
  let(:worker) { described_class.new }

  describe '#unique_key' do
    subject { worker.unique_key(request.id, {}) }
    it do
      is_expected.to eq("#{request.user_id}-#{request.uid}")
    end
  end

  describe '#after_skip' do
    subject { worker.after_skip(request.id) }
    it do
      expect(SkippedCreateTwitterUserWorker).to receive(:perform_async).with(request.id, {})
      subject
    end
  end

  describe '#after_expire' do
    subject { worker.after_expire(request.id) }
    it do
      expect(ExpiredCreateTwitterUserWorker).to receive(:perform_async).with(request.id, {})
      subject
    end
  end
end
