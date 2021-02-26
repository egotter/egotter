require 'rails_helper'

describe WelcomeReportStartingMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['初期設定 開始', '初期設定　開始', '初期設定開始'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#send_message' do
    subject { instance.send_message }

    it do
      expect(CreateWelcomeReportStartingMessageWorker).to receive(:perform_async).with(uid)
      subject
    end
  end
end
