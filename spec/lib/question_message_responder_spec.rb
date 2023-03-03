require 'rails_helper'

describe QuestionMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    [
        'プラン',
        'お試し',
        'トライアル',
        '通常の質問です',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it do
          is_expected.to be_truthy
          expect(instance.instance_variable_get(:@inquiry)).to be_truthy

        end
      end
    end

    [
        'ですか?',
        'ですか？',
        'ですか',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it do
          is_expected.to be_truthy
          expect(instance.instance_variable_get(:@question)).to be_truthy
        end
      end
    end

    [
        'これは？一体',
        '通常の質問ですよ'
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#send_message' do
    subject { instance.send_message }
    before { instance.instance_variable_set(:@inquiry, true) }
    it do
      expect(CreateQuestionMessageWorker).to receive(:perform_async).with(uid, text: 'text', inquiry: true)
      subject
    end
  end
end
