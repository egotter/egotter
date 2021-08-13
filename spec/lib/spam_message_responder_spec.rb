require 'rails_helper'

describe SpamMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['死ね', 'しね'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it do
          is_expected.to be_truthy
          expect(instance.instance_variable_get(:@spam)).to be_truthy
        end
      end
    end
  end

  describe '#received_regexp1' do
    subject { text.match?(instance.received_regexp1) }

    ['死ね', '殺す', '黙れ'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#received_regexp2' do
    subject { text.match?(instance.received_regexp2) }

    ['しね', 'くず', 'うざ'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['いってたしね', 'ゴミ掃除'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#send_message' do
    let(:user) { create(:user, uid: uid) }
    subject { instance.send_message }
    before do
      instance.instance_variable_set(:@spam, true)
      instance.instance_variable_set(:@uid, 1)
    end

    it do
      expect(CreateViolationEventWorker).to receive(:perform_async).with(user.id, 'Spam message')
      expect(CreateWarningReportSpamDetectedMessageWorker).to receive(:perform_async).with(uid)
      subject
    end
  end
end
