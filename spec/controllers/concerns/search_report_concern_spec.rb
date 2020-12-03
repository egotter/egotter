require 'rails_helper'

describe SearchReportConcern do
  let(:instance) { Object.new }

  before do
    instance.extend SearchReportConcern
  end

  describe '#process_search_report' do
    let(:dm) { double('dm', sender_id: 1, text: 'text') }
    let(:processor) { described_class::SearchReportProcessor.new(dm.sender_id, dm.text) }
    subject { instance.process_search_report(dm) }

    before do
      allow(described_class::SearchReportProcessor).to receive(:new).with(dm.sender_id, dm.text).and_return(processor)
    end

    it { is_expected.to be_falsey }

    context '#stop_requested? returns true' do
      before { allow(processor).to receive(:stop_requested?).and_return(true) }
      it do
        expect(processor).to receive(:stop_report)
        is_expected.to be_truthy
      end
    end

    context '#restart_requested? returns true' do
      before { allow(processor).to receive(:restart_requested?).and_return(true) }
      it do
        expect(processor).to receive(:restart_report)
        is_expected.to be_truthy
      end
    end

    context '#received? returns true' do
      before { allow(processor).to receive(:received?).and_return(true) }
      it { is_expected.to be_truthy }
    end

    context '#send_requested? returns true' do
      before { allow(processor).to receive(:send_requested?).and_return(true) }
      it { is_expected.to be_truthy }
    end
  end
end

describe SearchReportConcern::SearchReportProcessor do
  let(:user) { create(:user) }
  let(:text) { 'text' }
  let(:instance) { described_class.new(user.uid, text) }

  before do
    allow(instance).to receive(:validate_report_status).with(user.uid).and_return(user)
  end

  describe '#stop_requested?' do
    subject { instance.stop_requested? }

    ['【検索通知 停止】', '検索通知 停止', '検索通知停止'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#restart_requested?' do
    subject { instance.restart_requested? }

    ['【検索通知 再開】', '検索通知 再開', '検索通知再開'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#received?' do
    subject { instance.received? }

    ['検索通知 届きました'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#send_requested?' do
    subject { instance.send_requested? }

    ['【検索通知】', '検索通知'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#stop_report' do
    subject { instance.stop_report }

    it do
      expect(StopSearchReportRequest).to receive(:create).with(user_id: user.id)
      expect(CreateSearchReportStoppedMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#restart_report' do
    subject { instance.restart_report }

    it do
      expect(StopSearchReportRequest).to receive_message_chain(:find_by, :destroy).with(user_id: user.id).with(no_args)
      expect(CreateSearchReportRestartedMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end
end
