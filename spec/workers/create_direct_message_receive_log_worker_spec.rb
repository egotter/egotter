require 'rails_helper'

RSpec.describe CreateDirectMessageReceiveLogWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:text) { 'text' }
    let(:attrs) { {'sender_id' => 1, 'recipient_id' => 2, 'message' => text} }
    subject { worker.perform(attrs) }
    it { expect { subject }.to change { DirectMessageReceiveLog.all.size }.by(1) }

    context 'automated message' do
      let(:text) { 'text #egotter' }
      it do
        subject
        expect(DirectMessageReceiveLog.where(sender_id: 1, recipient_id: 2, automated: true).exists?).to be_truthy
      end
    end

    context 'NOT automated message' do
      let(:text) { 'text' }
      it do
        subject
        expect(DirectMessageReceiveLog.where(sender_id: 1, recipient_id: 2, automated: false).exists?).to be_truthy
      end
    end
  end
end
