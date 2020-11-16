require 'rails_helper'

describe PeriodicReportConcern do
  let(:instance) { Object.new }

  before do
    instance.extend PeriodicReportConcern
  end

  describe '#process_periodic_report' do
    let(:dm) { double('dm', sender_id: 1, text: 'text') }
    let(:processor) { described_class::PeriodicReportProcessor.new(dm.sender_id, dm.text) }
    subject { instance.process_periodic_report(dm) }

    before do
      allow(described_class::PeriodicReportProcessor).to receive(:new).with(dm.sender_id, dm.text).and_return(processor)
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

    context '#continue_requested? returns true' do
      before { allow(processor).to receive(:continue_requested?).and_return(true) }
      it do
        expect(processor).to receive(:continue_report)
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

  describe '#process_egotter_requested_periodic_report' do
    let(:dm) { double('dm', recipient_id: 1, text: 'text') }
    let(:processor) { described_class::PeriodicReportProcessor.new(dm.recipient_id, dm.text) }
    subject { instance.process_egotter_requested_periodic_report(dm) }

    before do
      allow(described_class::PeriodicReportProcessor).to receive(:new).with(dm.recipient_id, dm.text).and_return(processor)
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

    context '#send_requested? returns true' do
      before { allow(processor).to receive(:send_requested?).and_return(true) }
      it do
        expect(processor).to receive(:send_egotter_requested_report)
        is_expected.to be_truthy
      end
    end
  end
end

describe PeriodicReportConcern::PeriodicReportProcessor do
  let(:user) { create(:user) }
  let(:text) { 'text' }
  let(:instance) { described_class.new(user.uid, text) }

  before do
    allow(instance).to receive(:validate_report_status).with(user.uid).and_return(user)
  end

  describe '#stop_requested?' do
    subject { instance.stop_requested? }

    ['【リムられ通知 停止】', 'リムられ通知 停止', 'リムられ通知停止'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#restart_requested?' do
    subject { instance.restart_requested? }

    ['【リムられ通知 再開】', 'リムられ通知 再開', 'リムられ通知再開'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#continue_requested?' do
    subject { instance.continue_requested? }

    [
        '継続',
        '断続',
        '復活',
        '再会',
        'リムられ通知 継続',
        'リムられ通知 断続',
        'リムられ通知 復活',
        'リムられ通知 再会',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#received?' do
    subject { instance.received? }

    ['リムられ通知 届きました'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#send_requested?' do
    subject { instance.send_requested? }

    [
        'リム通知',
        'リムられ通知',
        'リムられた通知',
        'リム通知 今すぐ送信',
        'リムられ通知 今すぐ送信',
        'リムられた通知 今すぐ送信',
        '【リム通知 今すぐ送信】',
        '【リムられ通知 今すぐ送信】',
        '【リムられた通知 今すぐ送信】',
        '今すぐ',
        '今すぐ送信',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#stop_report' do
    subject { instance.stop_report }

    it do
      expect(DeleteRemindPeriodicReportRequestWorker).to receive(:perform_async).with(user.id)
      expect(StopPeriodicReportRequest).to receive(:create).with(user_id: user.id)
      expect(CreatePeriodicReportStopRequestedMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#restart_report' do
    subject { instance.restart_report }

    it do
      expect(DeleteRemindPeriodicReportRequestWorker).to receive(:perform_async).with(user.id)
      expect(StopPeriodicReportRequest).to receive_message_chain(:find_by, :destroy).with(user_id: user.id).with(no_args)
      expect(CreatePeriodicReportRestartRequestedMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#continue_report' do
    subject { instance.continue_report }

    it do
      expect(DeleteRemindPeriodicReportRequestWorker).to receive(:perform_async).with(user.id)
      expect(CreatePeriodicReportContinueRequestedMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#send_report' do
    subject { instance.send_report }

    before do
      allow(EgotterFollower).to receive(:exists?).with(uid: user.uid).and_return(true)
      expect(PeriodicReport).to receive(:interval_too_short?).with(user).and_return(false)
      expect(PeriodicReport).to receive(:access_interval_too_long?).with(user).and_return(false)
    end

    it do
      expect(DeleteRemindPeriodicReportRequestWorker).to receive(:perform_async).with(user.id)
      expect(CreatePeriodicReportRequest).to receive(:create).with(user_id: user.id, requested_by: 'user').and_call_original
      expect(CreateUserRequestedPeriodicReportWorker).to receive(:perform_async).with(any_args)
      subject
    end
  end

  describe '#send_egotter_requested_report' do
    subject { instance.send_egotter_requested_report }

    it do
      expect(CreatePeriodicReportRequest).to receive(:create).with(user_id: user.id, requested_by: 'egotter').and_call_original
      expect(CreateEgotterRequestedPeriodicReportWorker).to receive(:perform_async).with(any_args)
      subject
    end
  end
end
