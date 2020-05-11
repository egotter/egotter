require 'rails_helper'

RSpec.describe CreateSignedInTwitterUserWorker do
  let(:request) { create(:create_twitter_user_request) }
  let(:worker) { described_class.new }

  describe '#after_skip' do
    subject { worker.after_skip(request.id) }
    it do
      expect(SkippedCreateSignedInTwitterUserWorker).to receive(:perform_async).with(request.id, {})
      subject
    end
  end

  describe '#after_expire' do
    subject { worker.after_expire(request.id) }
    it do
      expect(ExpiredCreateSignedInTwitterUserWorker).to receive(:perform_async).with(request.id, {})
      subject
    end
  end
end
