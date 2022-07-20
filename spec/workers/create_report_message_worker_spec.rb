require 'rails_helper'

RSpec.describe CreateReportMessageWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:recipient) { create(:user) }
    let(:request) { create(:create_direct_message_request, recipient_id: recipient.uid) }
    before { allow(CreateDirectMessageRequest).to receive(:find).with(request.id).and_return(request) }
    subject { worker.perform(request.id) }
    it do
      expect(request).to receive(:perform)
      subject
    end
  end

  describe '#retry_later' do
    subject { worker.send(:retry_later, 1, 2, {}) }
    it do
      expect(described_class).to receive(:perform_in).
          with(1, 2, hash_including('requeued_at' => instance_of(ActiveSupport::TimeWithZone), 'requeue_count' => 1))
      subject
    end

    context 'requeue_count is 3' do
      subject { worker.send(:retry_later, 1, 2, {'requeue_count' => 3}) }
      it do
        expect(described_class).not_to receive(:perform_in)
        expect(Airbag).to receive(:warn).with(instance_of(String))
        subject
      end
    end
  end
end
