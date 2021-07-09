require 'rails_helper'

describe DeleteTweetsMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    [
        'ツイ消し',
        'つい消し',
        '削除',
        'クリーナー',
        'ツイート削除 開始 abc12'
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#send_message' do
    subject { instance.send_message }

    context '@inquiry is set' do
      before { instance.instance_variable_set(:@inquiry, true) }
      it do
        expect(CreateDeleteTweetsQuestionedMessageWorker).to receive(:perform_async).with(uid)
        subject
      end
    end

    context '@start is set' do
      before { instance.instance_variable_set(:@start, true) }
      it do
        expect(CreateDeleteTweetsInvalidRequestMessageWorker).to receive(:perform_async).with(uid)
        subject
      end
    end
  end
end
