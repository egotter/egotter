require 'rails_helper'

describe ThankYouMessageResponder::Processor do
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
      expect(CreateThankYouMessageWorker).to receive(:perform_async).with(uid)
      subject
    end
  end
end
