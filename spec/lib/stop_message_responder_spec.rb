require 'rails_helper'

describe StopMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['停止'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it do
          is_expected.to be_truthy
          expect(instance.instance_variable_get(:@stop)).to be_truthy
        end
      end
    end
  end

  describe '#stop_regexp' do
    subject { text.match?(instance.stop_regexp) }

    ['ストップ'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['解約'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#stop_all_regexp' do
    subject { text.match?(instance.stop_all_regexp) }

    ['全ての通知 停止', '全部の通知 停止', '全部の通知停止'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['リムられ通知 停止', 'ブロック通知 停止', 'ミュート通知 停止'].each do |word|
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
      instance.instance_variable_set(:@stop, true)
    end

    it do
      expect(CreatePeriodicReportHelpMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end
end
