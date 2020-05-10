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
        allow(DirectMessage).to receive(:new).with(anything).and_return(dm)
        allow(controller).to receive(:sent_from_user?).with(dm).and_return(true)
      end

      it do
        expect(GlobalDirectMessageReceivedFlag).to receive_message_chain(:new, :received).with(no_args).with(dm.sender_id)
        expect(SendReceivedMessageWorker).to receive(:perform_async).with(dm.sender_id, dm_id: dm.id, text: dm.text)
        subject
      end

      context 'restart_requested? returns true' do
        before { allow(controller).to receive(:restart_requested?).with(dm).and_return(true) }
        it do
          expect(controller).to receive(:enqueue_user_requested_restarting_periodic_report).with(dm)
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
          expect(controller).to receive(:enqueue_user_requested_periodic_report).with(dm)
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
end
