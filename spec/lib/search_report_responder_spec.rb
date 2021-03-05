require 'rails_helper'

describe SearchReportResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['検索通知'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it do
          is_expected.to be_truthy
          expect(instance.instance_variable_get(:@help)).to be_truthy
        end
      end
    end
  end

  describe '#restart_regexp' do
    subject { text.match?(instance.restart_regexp) }

    ['検索通知 再開'].each do |word|
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
      expect(CreateSearchReportHelpMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end
end
