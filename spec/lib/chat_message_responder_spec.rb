require 'rails_helper'

describe ChatMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['雑談', '何してるの？'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['https://t.co/xxx123', '@user'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#thanks_regexp' do
    subject { text.match?(instance.thanks_regexp) }

    ['ありがと', 'おつかれ'].each do |word|
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
    before { instance.instance_variable_set(:@chat, true) }

    it do
      expect(CreateChatMessageWorker).to receive(:perform_async).with(uid, text: 'text')
      subject
    end
  end
end
