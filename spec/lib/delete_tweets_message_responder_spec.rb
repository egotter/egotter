require 'rails_helper'

describe DeleteTweetsMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    [
        'ツイート削除 開始 abc123'
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it do
          is_expected.to be_truthy
          expect(instance.instance_variable_get(:@start)).to be_truthy
        end
      end
    end

    [
        'ツイ消し',
        'つい消し',
        '削除',
        'クリーナー',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it do
          is_expected.to be_truthy
          expect(instance.instance_variable_get(:@inquiry)).to be_truthy
        end
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
