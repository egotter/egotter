require 'rails_helper'

describe PeriodicReportResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['リムられ通知'].each do |word|
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

    ['リムられ通知 停止', 'リムられ 停止', 'リムられ通知停止'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['リムられ通知'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#send_regexp' do
    subject { text.match?(instance.send_regexp) }

    ['リムられ通知 送信', 'リムられ通知 今すぐ送信'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#help_regexp' do
    subject { text.match?(instance.help_regexp) }

    ['リムーブ', 'リムられ', 'リム', '通知', '再開', '継続', '今すぐ'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['継続って何？', 'リムとは', '再開してください', '今すぐ送信'].each do |word|
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
      allow(instance).to receive(:validate_report_status).with(uid).and_return(user)
      instance.instance_variable_set(:@help, true)
    end

    it do
      expect(CreatePeriodicReportHelpMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end
end
