require 'rails_helper'

RSpec.describe GlobalDirectMessageReceivedFlag, type: :model do
  let(:instance) { described_class.new }

  describe '#key' do
    subject { instance.key }
    it { is_expected.to eq("#{Rails.env}:GlobalDirectMessageReceivedFlag:86400:any_ids") }
  end

  describe '#cleanup' do
    subject { instance.cleanup }
    it do
      expect(SortedSetCleanupWorker).to receive(:perform_async).with(described_class)
      subject
    end

    context '#sync_mode is called' do
      before { instance.sync_mode }
      it do
        expect(SortedSetCleanupWorker).not_to receive(:perform_async)
        subject
      end
    end
  end
end
