require 'rails_helper'

describe BlockReportResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['ブロック通知'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it do
          is_expected.to be_truthy
          expect(instance.instance_variable_get(:@help)).to be_truthy
        end
      end
    end
  end

  describe '#stop_regexp' do
    subject { text.match?(instance.stop_regexp) }

    ['ブロック通知 停止', 'ブロック 停止', 'ブロック通知停止'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['ブロック通知'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#help_regexp' do
    subject { text.match?(instance.help_regexp) }

    ['ブロック', 'ぶろっく', 'ブロられ', 'ぶろられ'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#send_message' do
    let(:user) { create(:user, uid: uid) }
    subject { instance.send_message }
    before do
      allow(instance).to receive(:validate_report_status).with(uid).and_return(user)
      instance.instance_variable_set(:@help, true)
    end

    it do
      expect(CreateBlockReportHelpMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end
end
