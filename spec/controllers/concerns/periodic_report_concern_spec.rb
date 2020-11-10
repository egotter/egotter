require 'rails_helper'

describe PeriodicReportConcern, type: :controller do
  controller ApplicationController do
    include PeriodicReportConcern
  end

  let(:user) { create(:user, with_settings: true) }

  describe '#send_periodic_report_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:send_periodic_report_requested?, dm) }

    %w(リム通知 リムられ通知).product(%w(送信 そうしん 受信 じゅしん 痩身 通知 返信)).each do |word1, word2|
      context "text is #{word1 + word2}" do
        let(:text) { word1 + word2 }
        it { is_expected.to be_truthy }
      end
    end

    ['【リムられ通知 今すぐ送信】', 'リム通知 今すぐ送信'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#continue_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:continue_requested?, dm) }

    described_class::CONTINUE_WORDS.each do |word|
      context "text is #{word}" do
        let(:text) { 'a' + word + 'b' }
        it { is_expected.to be_truthy }
      end
    end

    ['あ', 'あー', 'リムられ通知'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    context "text is あいうえお" do
      let(:text) { 'あいうえお' }
      it { is_expected.to be_falsey }
    end

    context "text is #{I18n.t('quick_replies.prompt_reports.label1')}" do
      let(:text) { I18n.t('quick_replies.prompt_reports.label1') }
      it { is_expected.to be_falsey }
    end
  end

  describe '#stop_periodic_report_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:stop_periodic_report_requested?, dm) }

    [' ', '　', ''].product(%w(停止 ていし)).each do |word1, word2|
      context "text is リムられ通知#{word1 + word2}" do
        let(:text) { "リムられ通知#{word1 + word2}" }
        it { is_expected.to be_truthy }
      end
    end

    ['【リムられ通知 停止】'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#restart_periodic_report_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:restart_periodic_report_requested?, dm) }

    [' ', '　', ''].product(%w(再開 さいかい)).each do |word1, word2|
      context "text is リムられ通知#{word1 + word2}" do
        let(:text) { "リムられ通知#{word1 + word2}" }
        it { is_expected.to be_truthy }
      end
    end

    ['【リムられ通知 再開】'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#report_received?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:report_received?, dm) }

    context "text is 'リムられ通知 届きました'" do
      let(:text) { "リムられ通知 届きました" }
      it { is_expected.to be_truthy }
    end
  end

  describe '#enqueue_user_requested_periodic_report' do
    let(:dm) { double('dm', sender_id: user.uid) }
    subject { controller.send(:enqueue_user_requested_periodic_report, dm) }
    before { allow(controller).to receive(:validate_periodic_report_status).with(dm.sender_id).and_return(user) }
    it do
      expect(DeleteRemindPeriodicReportRequestWorker).to receive(:perform_async).with(user.id)
      expect(user).to receive(:has_valid_subscription?)
      expect(EgotterFollower).to receive(:exists?).with(uid: user.uid).and_return(true)
      expect(PeriodicReport).to receive(:interval_too_short?).with(user).and_return(false)
      expect(CreatePeriodicReportRequest).to receive(:create).with(user_id: user.id, requested_by: 'user').and_call_original
      expect(CreateUserRequestedPeriodicReportWorker).to receive(:perform_async).with(any_args)
      subject
    end
  end

  describe '#enqueue_egotter_requested_periodic_report' do
    let(:dm) { double('dm', recipient_id: user.uid) }
    subject { controller.send(:enqueue_egotter_requested_periodic_report, dm) }
    before { allow(controller).to receive(:validate_periodic_report_status).with(dm.recipient_id).and_return(user) }
    it do
      expect(CreatePeriodicReportRequest).to receive(:create).with(user_id: user.id, requested_by: 'egotter').and_call_original
      expect(CreateEgotterRequestedPeriodicReportWorker).to receive(:perform_async).with(any_args)
      subject
    end
  end

  describe '#stop_periodic_report' do
    let(:uid) { user.uid }
    subject { controller.send(:stop_periodic_report, uid) }
    before { allow(controller).to receive(:validate_periodic_report_status).with(uid).and_return(user) }
    it do
      expect(DeleteRemindPeriodicReportRequestWorker).to receive(:perform_async).with(user.id)
      expect(StopPeriodicReportRequest).to receive(:create).with(user_id: user.id)
      expect(CreatePeriodicReportStopRequestedMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#restart_periodic_report' do
    let(:uid) { user.uid }
    let(:request) { double('request', id: 1) }
    subject { controller.send(:restart_periodic_report, uid) }
    before { allow(controller).to receive(:validate_periodic_report_status).with(uid).and_return(user) }
    it do
      expect(DeleteRemindPeriodicReportRequestWorker).to receive(:perform_async).with(user.id)
      expect(StopPeriodicReportRequest).to receive_message_chain(:find_by, :destroy).with(user_id: user.id).with(no_args)
      expect(CreatePeriodicReportRestartRequestedMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#continue_periodic_report' do
    let(:uid) { user.uid }
    subject { controller.send(:continue_periodic_report, uid) }
    before { allow(controller).to receive(:validate_periodic_report_status).with(uid).and_return(user) }
    it do
      expect(DeleteRemindPeriodicReportRequestWorker).to receive(:perform_async).with(user.id)
      expect(CreatePeriodicReportContinueRequestedMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#validate_periodic_report_status' do
    let(:uid) { user.uid }
    subject { controller.send(:validate_periodic_report_status, uid) }

    before do
      allow(User).to receive(:find_by).with(uid: uid).and_return(user)
    end

    context 'user is not found' do
      before { allow(User).to receive(:find_by).with(uid: uid).and_return(nil) }
      it do
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(nil, unregistered: true, uid: uid)
        subject
      end
    end

    context 'user is not authorized' do
      before { user.update(authorized: false) }
      it do
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(user.id, unauthorized: true)
        subject
      end
    end

    context 'enough_permission_level? returns false' do
      before do
        allow(user).to receive_message_chain(:notification_setting, :enough_permission_level?).and_return(false)
      end
      it do
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(user.id, permission_level_not_enough: true)
        subject
      end
    end
  end
end
