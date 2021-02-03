require 'rails_helper'

describe PrettyIconMessageConcern do
  let(:instance) { Object.new }

  before do
    instance.extend PrettyIconMessageConcern
  end

  describe '#process_pretty_icon_message' do
    let(:dm) { double('dm', sender_id: 1, text: 'text') }
    let(:processor) { described_class::PrettyIconMessageProcessor.new(dm.sender_id, dm.text) }
    subject { instance.process_pretty_icon_message(dm) }

    before do
      allow(described_class::PrettyIconMessageProcessor).to receive(:new).with(dm.sender_id, dm.text).and_return(processor)
    end

    it { is_expected.to be_falsey }

    context '#received? returns true' do
      before { allow(processor).to receive(:received?).and_return(true) }
      it { is_expected.to be_truthy }
    end
  end
end

describe PrettyIconMessageConcern::PrettyIconMessageProcessor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['アイコン可愛い', 'アイコン可愛くなった？'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['おつかれんこん'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#send_message' do
    subject { instance.send_message }

    it do
      expect(CreatePrettyIconMessageWorker).to receive(:perform_async).with(uid)
      subject
    end
  end
end
