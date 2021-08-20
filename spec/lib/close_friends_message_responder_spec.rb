require 'rails_helper'

describe CloseFriendsMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    [
        '仲良し',
        '仲よし',
        'ランキング'
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#send_message' do
    subject { instance.send_message }

    it do
      expect(CreateCloseFriendsQuestionedMessageWorker).to receive(:perform_async).with(uid)
      subject
    end
  end
end
