require 'rails_helper'

describe SpamMessageConcern do
  let(:instance) { Object.new }

  before do
    instance.extend SpamMessageConcern
  end

  describe '#process_spam_message' do
    let(:dm) { double('dm', sender_id: 1, text: 'text') }
    let(:processor) { described_class::SpamMessageProcessor.new(dm.sender_id, dm.text) }
    subject { instance.process_spam_message(dm) }

    before do
      allow(described_class::SpamMessageProcessor).to receive(:new).with(dm.sender_id, dm.text).and_return(processor)
    end

    it { is_expected.to be_falsey }

    context '#breceived? returns true' do
      before { allow(processor).to receive(:received?).and_return(true) }
      it { is_expected.to be_truthy }
    end
  end
end

describe SpamMessageConcern::SpamMessageProcessor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['くず'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['いってたしね', 'ゴミ掃除'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#send_message' do
    subject { instance.send_message }

    it do
      expect(CreateWarningReportSpamDetectedMessageWorker).to receive(:perform_async).with(uid)
      subject
    end
  end
end
