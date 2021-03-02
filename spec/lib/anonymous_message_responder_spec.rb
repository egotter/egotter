require 'rails_helper'

describe AnonymousMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    context 'user is NOT persisted' do
      let(:user) { build(:user) }
      let(:uid) { user.uid }
      it { is_expected.to be_truthy }
    end

    context 'user is persisted' do
      let(:user) { create(:user) }
      let(:uid) { user.uid }
      it { is_expected.to be_falsey }
    end
  end

  describe '#send_message' do
    subject { instance.send_message }

    it do
      expect(CreateAnonymousMessageWorker).to receive(:perform_async).with(uid)
      subject
    end
  end
end
