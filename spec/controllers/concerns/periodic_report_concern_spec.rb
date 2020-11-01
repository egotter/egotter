require 'rails_helper'

describe PeriodicReportConcern, type: :controller do
  controller ApplicationController do
    include PeriodicReportConcern
  end

  let(:user) { create(:user) }

  describe '#send_now_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:send_now_requested?, dm) }

    %w(今すぐ いますぐ).product(%w(送信 そうしん 受信 じゅしん 痩身 通知 返信)).each do |word1, word2|
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

  describe '#send_now_exactly_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:send_now_exactly_requested?, dm) }

    ['リムられ通知 今すぐ送信'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['【リムられ通知 今すぐ送信】'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#continue_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:continue_requested?, dm) }

    described_class::CONTINUE_WORDS.each do |word|
      context "text is #{word}" do
        let(:text) { SecureRandom.hex(1) + word + SecureRandom.hex(1) }
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

  describe '#stop_now_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:stop_now_requested?, dm) }

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

  describe '#stop_now_exactly_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:stop_now_exactly_requested?, dm) }

    ['リムられ通知 停止'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['【リムられ通知 停止】'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#restart_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:restart_requested?, dm) }

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

  describe '#restart_exactly_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:restart_exactly_requested?, dm) }

    ['リムられ通知 再開'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['【リムられ通知 再開】'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
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
    shared_context 'find_by returns user' do
      before { allow(User).to receive(:find_by).with(uid: dm.sender_id).and_return(user) }
    end

    shared_context 'user is unauthorized' do
      before { user.update(authorized: false) }
    end

    let(:user) { create(:user) }
    let(:dm) { double('dm', sender_id: user.uid) }
    subject { controller.send(:enqueue_user_requested_periodic_report, dm) }

    context 'user is not found' do
      before { allow(User).to receive(:find_by).with(uid: dm.sender_id).and_return(nil) }

      it do
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(nil, unregistered: true, uid: dm.sender_id)
        subject
      end
    end

    context 'user is authorized' do
      include_context 'find_by returns user'
      let(:request) { create(:create_periodic_report_request, user: user) }

      shared_examples 'enqueue one job' do
        it do
          expect(CreatePeriodicReportRequest).to receive(:create).with(user_id: user.id, requested_by: 'user').and_return(request)
          expect(CreateUserRequestedPeriodicReportWorker).to receive(:perform_async).with(request.id, user_id: user.id)
          subject
        end
      end

      shared_examples 'enqueue no job' do
        it do
          expect(CreatePeriodicReportRequest).not_to receive(:create)
          subject
        end
      end

      context 'fuzzy is false (not specified)' do
        include_examples 'enqueue one job'
      end

      context 'fuzzy is true' do
        subject { controller.send(:enqueue_user_requested_periodic_report, dm, fuzzy: true) }

        context 'sufficient_interval? returns true' do
          before { allow(CreatePeriodicReportRequest).to receive(:sufficient_interval?).with(user.id).and_return(true) }
          include_examples 'enqueue one job'
        end

        context 'sufficient_interval? returns false' do
          before { allow(CreatePeriodicReportRequest).to receive(:sufficient_interval?).with(user.id).and_return(false) }
          include_examples 'enqueue no job'
        end
      end
    end

    context 'enough_permission_level? returns false' do
      include_context 'find_by returns user'
      include_context 'user is unauthorized'
      before do
        allow(user).to receive_message_chain(:notification_setting, :enough_permission_level?).and_return(false)
      end

      it do
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).
            with(user.id, permission_level_not_enough: true)
        subject
      end
    end

    context 'else' do
      include_context 'find_by returns user'
      include_context 'user is unauthorized'
      before do
        allow(user).to receive_message_chain(:notification_setting, :enough_permission_level?).and_return(true)
      end

      it do
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(user.id, unauthorized: true)
        subject
      end
    end
  end

  describe '#enqueue_user_received_periodic_report' do
    let(:user) { create(:user) }
    let(:dm) { double('dm', sender_id: user.uid) }
    subject { controller.send(:enqueue_user_received_periodic_report, dm) }

    context 'user is found' do
      let(:request) { create(:create_periodic_report_request, user: user) }

      before do
        allow(User).to receive(:find_by).with(uid: dm.sender_id).and_return(user)
        allow(EgotterFollower).to receive(:exists?).with(uid: user.uid).and_return(true)
      end

      it do
        expect(CreatePeriodicReportRequest).to receive(:create).with(user_id: user.id, requested_by: 'user').and_return(request)
        expect(CreateUserRequestedPeriodicReportWorker).to receive(:perform_async).with(request.id, user_id: user.id)
        subject
      end
    end
  end

  describe '#enqueue_user_requested_stopping_periodic_report' do
    let(:dm) { double('dm', sender_id: 1) }
    subject { controller.send(:enqueue_user_requested_stopping_periodic_report, dm) }
    it do
      expect(controller).to receive(:stop_periodic_report).with(dm.sender_id)
      subject
    end
  end

  describe '#enqueue_user_requested_restarting_periodic_report' do
    let(:dm) { double('dm', sender_id: 1) }
    subject { controller.send(:enqueue_user_requested_restarting_periodic_report, dm) }
    it do
      expect(controller).to receive(:restart_periodic_report).with(dm.sender_id)
      subject
    end
  end

  describe '#enqueue_egotter_requested_periodic_report' do
    shared_context 'find_by returns user' do
      before { allow(User).to receive(:find_by).with(uid: dm.recipient_id).and_return(user) }
    end

    shared_context 'user is unauthorized' do
      before { user.update(authorized: false) }
    end

    let(:user) { create(:user) }
    let(:dm) { double('dm', recipient_id: user.uid) }
    subject { controller.send(:enqueue_egotter_requested_periodic_report, dm) }

    context 'user is not found' do
      before { allow(User).to receive(:find_by).with(uid: dm.recipient_id).and_return(nil) }

      it do
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(nil, unregistered: true, uid: dm.recipient_id)
        subject
      end
    end

    context 'user is authorized' do
      include_context 'find_by returns user'
      let(:request) { create(:create_periodic_report_request, user: user) }

      it do
        expect(CreatePeriodicReportRequest).to receive(:create).with(user_id: user.id, requested_by: 'egotter').and_return(request)
        expect(CreateEgotterRequestedPeriodicReportWorker).to receive(:perform_async).with(request.id, user_id: user.id)
        subject
      end
    end

    context 'enough_permission_level? returns false' do
      include_context 'find_by returns user'
      include_context 'user is unauthorized'
      before do
        allow(user).to receive_message_chain(:notification_setting, :enough_permission_level?).and_return(false)
      end

      it do
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).
            with(user.id, permission_level_not_enough: true)
        subject
      end
    end

    context 'else' do
      include_context 'find_by returns user'
      include_context 'user is unauthorized'
      before do
        allow(user).to receive_message_chain(:notification_setting, :enough_permission_level?).and_return(true)
      end

      it do
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).
            with(user.id, unauthorized: true)
        subject
      end
    end
  end

  describe '#enqueue_egotter_requested_stopping_periodic_report' do
    let(:dm) { double('dm', recipient_id: 1) }
    subject { controller.send(:enqueue_egotter_requested_stopping_periodic_report, dm) }
    it do
      expect(controller).to receive(:stop_periodic_report).with(dm.recipient_id)
      subject
    end
  end

  describe '#enqueue_egotter_requested_restarting_periodic_report' do
    let(:dm) { double('dm', recipient_id: 1) }
    subject { controller.send(:enqueue_egotter_requested_restarting_periodic_report, dm) }
    it do
      expect(controller).to receive(:restart_periodic_report).with(dm.recipient_id)
      subject
    end
  end

  describe '#stop_periodic_report' do
    let(:uid) { 1 }
    subject { controller.send(:stop_periodic_report, uid) }

    context 'user is found' do
      let(:user) { create(:user, uid: uid) }
      before { allow(User).to receive(:find_by).with(uid: uid).and_return(user) }
      it do
        expect(StopPeriodicReportRequest).to receive(:create).with(user_id: user.id)
        expect(CreatePeriodicReportStopRequestedMessageWorker).to receive(:perform_async).with(user.id)
        subject
      end
    end

    context 'user is not found' do
      before { allow(User).to receive(:find_by).with(uid: uid).and_return(nil) }
      it do
        expect(StopPeriodicReportRequest).not_to receive(:create)
        subject
      end
    end
  end

  describe '#restart_periodic_report' do
    let(:uid) { 1 }
    subject { controller.send(:restart_periodic_report, uid) }

    context 'user is found' do
      let(:user) { create(:user, uid: uid) }
      before { allow(User).to receive(:find_by).with(uid: uid).and_return(user) }
      it do
        expect(StopPeriodicReportRequest).to receive_message_chain(:find_by, :destroy).with(user_id: user.id).with(no_args)
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(user.id, restart_requested: true)
        subject
      end
    end

    context 'user is not found' do
      before { allow(User).to receive(:find_by).with(uid: uid).and_return(nil) }
      it do
        expect(StopPeriodicReportRequest).not_to receive(:find_by)
        subject
      end
    end
  end
end
