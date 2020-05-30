require 'rails_helper'

RSpec.describe GlobalTotalDirectMessageReceivedFlag, type: :model do
  let(:instance) { described_class.new }

  describe '#key' do
    subject { instance.key }
    it { is_expected.to eq("#{Rails.env}:GlobalTotalDirectMessageReceivedFlag:86400:any_ids") }
  end

  describe '#cleanup' do
    subject { instance.cleanup }
    it do
      expect(SortedSetCleanupWorker).not_to receive(:perform_async)
      subject
    end
  end
end
