require 'rails_helper'

RSpec.describe WebhookController, type: :controller do

  describe 'POST #twitter' do
    let(:params) { {direct_message_events: ['event1', 'event2']} }
    subject { post :twitter, params: params }

    before do
      allow(controller).to receive(:verified_webhook_request?).and_return(true)
      allow(controller).to receive(:direct_message_event_for_egotter?).and_return(true)
    end

    it do
      params[:direct_message_events].each do |event|
        expect(controller).to receive(:process_direct_message_event).with(event)
      end
      is_expected.to have_http_status(:ok)
    end
  end

  describe '#direct_message_event_for_egotter?' do
    subject { controller.send(:direct_message_event_for_egotter?) }
    before do
      allow(controller.params).to receive(:[]).with(:for_user_id).and_return(User::EGOTTER_UID.to_s)
      allow(controller.params).to receive(:[]).with(:direct_message_events).and_return('events')
    end
    it { is_expected.to be_truthy }
  end

  describe '#process_direct_message_event' do
    shared_context 'event[type] is message_create' do
      before { allow(event).to receive(:[]).with('type').and_return('message_create') }
    end

    shared_context 'correct event is passed' do
      let(:dm) { double('dm', sender_id: 1, recipient_id: 2, text: 'text') }
      before { allow(DirectMessage).to receive(:new).with(anything).and_return(dm) }
    end

    shared_context 'skip processing messages' do
      before do
        allow(controller).to receive(:sent_from_user?).with(dm).and_return(false)
        allow(controller).to receive(:sent_from_egotter?).with(dm).and_return(false)
      end
    end

    shared_context 'skip setting global flags' do
      before do
        allow(controller).to receive(:message_from_user?).with(dm).and_return(false)
        allow(controller).to receive(:message_from_egotter?).with(dm).and_return(false)
      end
    end

    let(:event) { {'type' => 'type'} }
    subject { controller.send(:process_direct_message_event, event) }

    context 'event[type] is not message_create' do
      it { is_expected.to be_falsey }
    end

    context 'sent_from_user? returns true' do
      include_context 'event[type] is message_create'
      include_context 'correct event is passed'
      include_context 'skip setting global flags'
      before { allow(controller).to receive(:sent_from_user?).with(dm).and_return(true) }
      it do
        expect(controller).to receive(:process_message_from_user).with(dm)
        subject
      end
    end

    context 'sent_from_egotter? returns true' do
      include_context 'event[type] is message_create'
      include_context 'correct event is passed'
      include_context 'skip setting global flags'
      before do
        allow(controller).to receive(:sent_from_user?).with(dm).and_return(false)
        allow(controller).to receive(:sent_from_egotter?).with(dm).and_return(true)
      end
      it do
        expect(controller).to receive(:process_message_from_egotter).with(dm)
        subject
      end
    end

    context 'message_from_user? returns true' do
      include_context 'event[type] is message_create'
      include_context 'correct event is passed'
      include_context 'skip processing messages'
      before { allow(controller).to receive(:message_from_user?).with(dm).and_return(true) }
      it do
        expect(GlobalTotalDirectMessageReceivedFlag).to receive_message_chain(:new, :received).with(dm.sender_id)
        subject
      end
    end

    context 'message_from_egotter? returns true' do
      include_context 'event[type] is message_create'
      include_context 'correct event is passed'
      include_context 'skip processing messages'
      before do
        allow(controller).to receive(:message_from_user?).with(dm).and_return(false)
        allow(controller).to receive(:message_from_egotter?).with(dm).and_return(true)
      end
      it do
        expect(GlobalTotalDirectMessageSentFlag).to receive_message_chain(:new, :received).with(dm.recipient_id)
        subject
      end
    end
  end

  describe '#process_message_from_user' do
    let(:dm) { double('dm', sender_id: 'sender_id', id: 'id', text: 'text') }
    subject { controller.send(:process_message_from_user, dm) }

    it do
      expect(GlobalDirectMessageReceivedFlag).to receive_message_chain(:new, :received).with(dm.sender_id)
      expect(SendReceivedMessageWorker).to receive(:perform_async).with(dm.sender_id, dm_id: dm.id, text: dm.text)
      subject
    end

    context 'restart_requested? returns true' do
      before { allow(controller).to receive(:restart_requested?).with(dm).and_return(true) }
      it do
        expect(controller).to receive(:enqueue_user_requested_restarting_periodic_report).with(dm)
        expect(controller).to receive(:enqueue_user_requested_periodic_report).with(dm)
        subject
      end
    end

    context 'send_now_requested? returns true' do
      before { allow(controller).to receive(:send_now_requested?).with(dm).and_return(true) }
      it do
        expect(controller).to receive(:enqueue_user_requested_periodic_report).with(dm)
        subject
      end
    end

    context 'continue_requested? returns true' do
      before { allow(controller).to receive(:continue_requested?).with(dm).and_return(true) }
      it do
        expect(controller).to receive(:enqueue_user_requested_periodic_report).with(dm, fuzzy: true)
        subject
      end
    end

    context 'stop_now_requested? returns true' do
      before { allow(controller).to receive(:stop_now_requested?).with(dm).and_return(true) }
      it do
        expect(controller).to receive(:enqueue_user_requested_stopping_periodic_report).with(dm)
        subject
      end
    end

    context 'report_received? returns true' do
      before { allow(controller).to receive(:report_received?).with(dm).and_return(true) }
      it do
        expect(controller).to receive(:enqueue_user_received_periodic_report).with(dm)
        subject
      end
    end
  end

  describe '#process_message_from_egotter' do
    let(:dm) { double('dm', recipient_id: 'recipient_id', id: 'id', text: 'text') }
    subject { controller.send(:process_message_from_egotter, dm) }

    it do
      expect(GlobalDirectMessageSentFlag).to receive_message_chain(:new, :received).with(dm.recipient_id)
      expect(SendSentMessageWorker).to receive(:perform_async).with(dm.recipient_id, dm_id: dm.id, text: dm.text)
      subject
    end

    context 'send_now_requested? returns true' do
      before { allow(controller).to receive(:send_now_requested?).with(dm).and_return(true) }
      it do
        expect(controller).to receive(:enqueue_egotter_requested_periodic_report).with(dm)
        subject
      end
    end
  end

  describe '#sent_from_user?' do
    let(:dm) { double('dm', id: 1, sender_id: 1, text: text) }
    subject { controller.send(:sent_from_user?, dm) }

    context 'text includes #egotter' do
      let(:text) { 'hello #egotter' }
      it { is_expected.to be_falsey }
    end

    [
        I18n.t('quick_replies.prompt_reports.label1'),
        I18n.t('quick_replies.prompt_reports.label2'),
        I18n.t('quick_replies.prompt_reports.label3'),
        I18n.t('quick_replies.prompt_reports.label4'),
        I18n.t('quick_replies.prompt_reports.label5')
    ].each do |text_command|
      context "text is #{text_command}" do
        let(:text) { text_command }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#sent_from_egotter?' do
    let(:dm) { double('dm', id: 1, sender_id: User::EGOTTER_UID, text: text) }
    subject { controller.send(:sent_from_egotter?, dm) }

    context 'text includes #egotter' do
      let(:text) { 'hello #egotter' }
      it { is_expected.to be_falsey }
    end

    [
        I18n.t('quick_replies.prompt_reports.label3')
    ].each do |text_command|
      context "text is #{text_command}" do
        let(:text) { text_command }
        it { is_expected.to be_truthy }
      end
    end
  end
end
