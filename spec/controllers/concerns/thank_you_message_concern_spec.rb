require 'rails_helper'

describe ThankYouMessageConcern do
  let(:instance) { Object.new }

  before do
    instance.extend ThankYouMessageConcern
  end

  describe '#process_thank_you_message' do
    let(:dm) { double('dm', sender_id: 1, text: 'text') }
    let(:processor) { described_class::ThankYouMessageProcessor.new(dm.sender_id, dm.text) }
    subject { instance.process_thank_you_message(dm) }

    before do
      allow(described_class::ThankYouMessageProcessor).to receive(:new).with(dm.sender_id, dm.text).and_return(processor)
    end

    it { is_expected.to be_falsey }

    context '#received? returns true' do
      before { allow(processor).to receive(:received?).and_return(true) }
      it { is_expected.to be_truthy }
    end
  end
end

describe ThankYouMessageConcern::ThankYouMessageProcessor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['ありがとう', '有難う'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#send_message' do
    subject { instance.send_message }

    it do
      expect(CreateThankYouMessageWorker).to receive(:perform_async).with(uid)
      subject
    end
  end
end
