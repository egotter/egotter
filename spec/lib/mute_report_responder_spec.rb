require 'rails_helper'

describe MuteReportResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['ミュート通知'].each do |word|
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

    ['ミュート通知 停止', 'ミュート 停止', 'ミュート通知停止'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['ミュート通知'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#send_message' do
    let(:user) { create(:user, uid: uid) }
    subject { instance.send_message }
    before { allow(instance).to receive(:validate_report_status).with(uid).and_return(user) }

    context 'help is requested' do
      before { instance.instance_variable_set(:@help, true) }
      it do
        expect(CreateMuteReportHelpMessageWorker).to receive(:perform_async).with(user.id)
        subject
      end
    end

    context 'send is requested' do
      before { instance.instance_variable_set(:@send, true) }

      it do
        expect(CreateMuteReportByUserRequestWorker).to receive(:perform_async).with(user.id)
        subject
      end

      context 'stop is already requested' do
        before { create(:stop_mute_report_request, user_id: user.id) }
        it do
          expect(CreateMuteReportStopRequestedWorker).to receive(:perform_async).with(user.id)
          subject
        end
      end
    end
  end
end
