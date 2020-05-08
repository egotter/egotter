require 'rails_helper'

RSpec.describe WebhookController, type: :controller do

  describe 'POST #twitter' do
    let(:params) do
      {
          for_user_id: User::EGOTTER_UID,
          direct_message_events: [
              {'type' => 'message_create', 'event' => double('event')}
          ]
      }
    end
    subject { post :twitter, params: params }

    before do
      allow(controller).to receive(:verified_webhook_request?).and_return(true)
      allow(User).to receive_message_chain(:egotter, :uid).and_return(User::EGOTTER_UID)
    end

    it do
      is_expected.to have_http_status(:ok)
    end

    context 'sent_from_user? returns true' do
      let(:dm) { double('dm', id: 1, sender_id: 2, text: 'text') }
      before do
        allow(controller).to receive(:sent_from_user?).with(dm).and_return(true)
      end

      it do
        expect(DirectMessage).to receive(:new).with(anything).and_return(dm)
        expect(GlobalDirectMessageReceivedFlag).to receive_message_chain(:new, :received).with(no_args).with(dm.sender_id)
        expect(controller).to receive(:enqueue_user_requested_periodic_report).with(dm)
        expect(SendReceivedMessageWorker).to receive(:perform_async).with(dm.sender_id, dm_id: dm.id, text: dm.text)
        subject
      end
    end

    context 'sent_from_egotter? returns true' do
      let(:dm) { double('dm', id: 1, recipient_id: 2, text: 'text') }
      before do
        allow(controller).to receive(:sent_from_user?).with(dm).and_return(false)
        allow(controller).to receive(:sent_from_egotter?).with(dm).and_return(true)
      end

      it do
        expect(DirectMessage).to receive(:new).with(anything).and_return(dm)
        expect(controller).to receive(:enqueue_egotter_requested_periodic_report).with(dm)
        expect(SendSentMessageWorker).to receive(:perform_async).with(dm.recipient_id, dm_id: dm.id, text: dm.text)
        subject
      end
    end
  end

  describe '#send_now_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:send_now_requested?, dm) }

    %w(今すぐ いますぐ).product(%w(送信 そうしん 受信 じゅしん 痩身 通知)).each do |word1, word2|
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
