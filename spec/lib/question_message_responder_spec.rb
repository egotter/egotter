require 'rails_helper'

describe QuestionMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    [
        'ですか?',
        'ですか？',
        'ですか',
        'プラン',
        'お試し',
        'トライアル',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['これは？一体'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#send_message' do
    subject { instance.send_message }

    it do
      expect(CreateQuestionMessageWorker).to receive(:perform_async).with(uid, text: 'text')
      subject
    end
  end
end
