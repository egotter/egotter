require 'rails_helper'

describe BlockReportConcern do
  let(:instance) { Object.new }

  before do
    instance.extend BlockReportConcern
  end

  describe '#process_block_report' do
    let(:dm) { double('dm', sender_id: 1, text: 'text') }
    let(:processor) { described_class::BlockReportProcessor.new(dm.sender_id, dm.text) }
    subject { instance.process_block_report(dm) }

    before do
      allow(described_class::BlockReportProcessor).to receive(:new).with(dm.sender_id, dm.text).and_return(processor)
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
      it do
        expect(processor).to receive(:send_report)
        is_expected.to be_truthy
      end
    end
  end
end

describe BlockReportConcern::BlockReportProcessor do
  let(:user) { create(:user) }
  let(:text) { 'text' }
  let(:instance) { described_class.new(user.uid, text) }

  before do
    allow(instance).to receive(:validate_report_status).with(user.uid).and_return(user)
  end

  describe '#stop_requested?' do
    subject { instance.stop_requested? }

    ['【ブロック通知 停止】', 'ブロック通知 停止', 'ブロック通知停止', 'ブロられ通知 停止'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#restart_requested?' do
    subject { instance.restart_requested? }

    ['【ブロック通知 再開】', 'ブロック通知 再開', 'ブロック通知再開', 'ブロられ通知 再開'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#received?' do
    subject { instance.received? }

    ['ブロック通知 届きました'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#send_requested?' do
    subject { instance.send_requested? }

    ['【ブロック通知】', 'ブロック通知', 'ブロられ通知', 'ブロック'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#stop_report' do
    subject { instance.stop_report }

    it do
      expect(StopBlockReportRequest).to receive(:create).with(user_id: user.id)
      expect(CreateBlockReportStoppedMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#restart_report' do
    subject { instance.restart_report }

    it do
      expect(StopBlockReportRequest).to receive_message_chain(:find_by, :destroy).with(user_id: user.id).with(no_args)
      expect(CreateBlockReportRestartedMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#send_report' do
    subject { instance.send_report }

    it do
      expect(CreateBlockReportWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end
end
