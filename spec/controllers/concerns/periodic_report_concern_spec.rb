require 'rails_helper'

describe Concerns::PeriodicReportConcern, type: :controller do
  controller ApplicationController do
    include Concerns::PeriodicReportConcern
  end

  let(:user) { create(:user) }

  describe '#send_now_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:send_now_requested?, dm) }

    %w(今すぐ いますぐ).product(%w(送信 そうしん 受信 じゅしん 痩身 通知 返信)).each do |word1, word2|
      context "text is #{word1 + word2}" do
        let(:text) { SecureRandom.hex(1) + word1 + word2 + SecureRandom.hex(1) }
        it { is_expected.to be_truthy }
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
  end

  describe '#enqueue_user_requested_periodic_report' do
    shared_context 'send_now_requested? returns true' do
      before { allow(controller).to receive(:send_now_requested?).with(dm).and_return(true) }
    end

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
      include_context 'send_now_requested? returns true'
      before { allow(User).to receive(:find_by).with(uid: dm.sender_id).and_return(nil) }

      it do
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(nil, unregistered: true, uid: dm.sender_id)
        subject
      end
    end

    context 'user is authorized' do
      include_context 'send_now_requested? returns true'
      include_context 'find_by returns user'
      let(:request) { create(:create_periodic_report_request, user: user) }

      it do
        expect(CreatePeriodicReportRequest).to receive(:create).with(user_id: user.id).and_return(request)
        expect(CreateUserRequestedPeriodicReportWorker).to receive(:perform_async).
            with(request.id, user_id: user.id, create_twitter_user: true)
        subject
      end
    end

    context 'enough_permission_level? returns false' do
      include_context 'send_now_requested? returns true'
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
      include_context 'send_now_requested? returns true'
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

    context 'send_now_requested? returns false and continue_requested? return false' do
      before do
        allow(controller).to receive(:send_now_requested?).with(dm).and_return(false)
        allow(controller).to receive(:continue_requested?).with(dm).and_return(false)
      end
      it do
        expect(User).not_to receive(:find_by)
        subject
      end
    end
  end

  describe '#enqueue_user_requested_stopping_periodic_report' do
    shared_context 'stop_now_requested? returns true' do
      before { allow(controller).to receive(:stop_now_requested?).with(dm).and_return(true) }
    end

    shared_context 'find_by returns user' do
      before { allow(User).to receive(:find_by).with(uid: dm.sender_id).and_return(user) }
    end

    let(:user) { create(:user) }
    let(:dm) { double('dm', sender_id: user.uid) }
    subject { controller.send(:enqueue_user_requested_stopping_periodic_report, dm) }

    context 'user is found' do
      include_context 'stop_now_requested? returns true'
      include_context 'find_by returns user'
      it do
        expect(StopPeriodicReportRequest).to receive(:create).with(user_id: user.id)
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(nil, stop_requested: true, uid: dm.sender_id)
        subject
      end
    end

    context 'user is not found' do
      include_context 'stop_now_requested? returns true'
      before { allow(User).to receive(:find_by).with(uid: dm.sender_id).and_return(nil) }
      it do
        expect(StopPeriodicReportRequest).not_to receive(:create)
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(nil, stop_requested: true, uid: dm.sender_id)
        subject
      end
    end

    context 'stop_now_requested? returns false' do
      before do
        allow(controller).to receive(:stop_now_requested?).with(dm).and_return(false)
      end
      it do
        expect(User).not_to receive(:find_by)
        subject
      end
    end
  end

  describe '#enqueue_user_requested_restarting_periodic_report' do
    shared_context 'restart_requested? returns true' do
      before { allow(controller).to receive(:restart_requested?).with(dm).and_return(true) }
    end

    shared_context 'find_by returns user' do
      before { allow(User).to receive(:find_by).with(uid: dm.sender_id).and_return(user) }
    end

    let(:user) { create(:user) }
    let(:dm) { double('dm', sender_id: user.uid) }
    subject { controller.send(:enqueue_user_requested_restarting_periodic_report, dm) }

    context 'user is found' do
      include_context 'restart_requested? returns true'
      include_context 'find_by returns user'
      it do
        expect(StopPeriodicReportRequest).to receive_message_chain(:find_by, :destroy).with(user_id: user.id).with(no_args)
        subject
      end
    end

    context 'user is not found' do
      include_context 'restart_requested? returns true'
      before { allow(User).to receive(:find_by).with(uid: dm.sender_id).and_return(nil) }
      it do
        expect(StopPeriodicReportRequest).not_to receive(:destroy)
        subject
      end
    end

    context 'restart_requested? returns false' do
      before do
        allow(controller).to receive(:restart_requested?).with(dm).and_return(false)
      end
      it do
        expect(User).not_to receive(:find_by)
        subject
      end
    end
  end

  describe '#enqueue_egotter_requested_periodic_report' do
    shared_context 'send_now_requested? returns true' do
      before { allow(controller).to receive(:send_now_requested?).with(dm).and_return(true) }
    end

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
      include_context 'send_now_requested? returns true'
      before { allow(User).to receive(:find_by).with(uid: dm.recipient_id).and_return(nil) }

      it do
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(nil, unregistered: true, uid: dm.recipient_id)
        subject
      end
    end

    context 'user is authorized' do
      include_context 'send_now_requested? returns true'
      include_context 'find_by returns user'
      let(:request) { create(:create_periodic_report_request, user: user) }

      it do
        expect(CreatePeriodicReportRequest).to receive(:create).with(user_id: user.id).and_return(request)
        expect(CreateEgotterRequestedPeriodicReportWorker).to receive(:perform_async).
            with(request.id, user_id: user.id, create_twitter_user: true)
        subject
      end
    end

    context 'enough_permission_level? returns false' do
      include_context 'send_now_requested? returns true'
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
      include_context 'send_now_requested? returns true'
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

    context 'send_now_requested? returns false' do
      before { allow(controller).to receive(:send_now_requested?).with(dm).and_return(false) }
      it do
        expect(User).not_to receive(:find_by)
        subject
      end
    end
  end
end
