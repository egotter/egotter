require 'rails_helper'

RSpec.describe ProcessWebhookEventWorker do
  let(:worker) { described_class.new }

  describe '#unique_key' do
    subject { worker.unique_key('event') }
    it { is_expected.to eq(Digest::MD5.hexdigest('event'.inspect)) }
  end

  describe '#after_skip' do
    subject { worker.after_skip('event') }
    it do
      expect(Airbag).to receive(:info).with(instance_of(String))
      subject
    end
  end

  describe '#perform' do
    subject { worker.perform(event) }

    context 'event[type] is not message_create' do
      let(:event) { {'type' => 'type'} }
      it do
        expect(worker).not_to receive(:process_direct_message_event)
        subject
      end
    end

    context 'event[type] is message_create' do
      let(:event) { {'type' => 'message_create'} }
      it do
        expect(worker).to receive(:process_direct_message_event).with(event)
        subject
      end
    end
  end

  describe '#process_direct_message_event' do
    shared_context 'correct event is passed' do
      let(:dm) { double('dm', sender_id: 1, recipient_id: 2, text: 'text') }
      before { allow(DirectMessageWrapper).to receive(:new).with(anything).and_return(dm) }
    end

    shared_context 'skip processing messages' do
      before do
        allow(worker).to receive(:sent_from_user?).with(dm).and_return(false)
        allow(worker).to receive(:sent_from_egotter?).with(dm).and_return(false)
      end
    end

    shared_context 'skip setting global flags' do
      before do
        allow(worker).to receive(:message_from_user?).with(dm).and_return(false)
        allow(worker).to receive(:message_from_egotter?).with(dm).and_return(false)
      end
    end

    let(:event) { {'type' => 'type'} }
    subject { worker.send(:process_direct_message_event, event) }

    context 'sent_from_user? returns true' do
      include_context 'correct event is passed'
      include_context 'skip setting global flags'
      before { allow(worker).to receive(:sent_from_user?).with(dm).and_return(true) }
      it do
        expect(worker).to receive(:process_message_from_user).with(dm)
        subject
      end
    end

    context 'sent_from_egotter? returns true' do
      include_context 'correct event is passed'
      include_context 'skip setting global flags'
      before do
        allow(worker).to receive(:sent_from_user?).with(dm).and_return(false)
        allow(worker).to receive(:sent_from_egotter?).with(dm).and_return(true)
      end
      it do
        expect(worker).to receive(:process_message_from_egotter).with(dm)
        subject
      end
    end

    context 'message_from_user? returns true' do
      include_context 'correct event is passed'
      include_context 'skip processing messages'
      before { allow(worker).to receive(:message_from_user?).with(dm).and_return(true) }
      it do
        expect(CreateDirectMessageReceiveLogWorker).to receive(:perform_async).with(sender_id: dm.sender_id, recipient_id: dm.recipient_id, message: dm.text)
        subject
      end
    end
  end

  describe '#process_message_from_user' do
    let(:dm) { double('dm', sender_id: 'sender_id', id: 'id', text: 'text') }
    subject { worker.send(:process_message_from_user, dm) }

    it do
      expect(GlobalDirectMessageReceivedFlag).to receive_message_chain(:new, :received).with(dm.sender_id)
      expect(DirectMessageSendCounter).to receive(:clear).with(dm.sender_id)
      [
          PeriodicReportResponder,
          BlockReportResponder,
          MuteReportResponder,
          SearchReportResponder,
          WelcomeReportResponder,
          StopMessageResponder,
          DeleteTweetsMessageResponder,
          CloseFriendsMessageResponder,
          ThankYouMessageResponder,
          PrettyIconMessageResponder,
          SpamMessageResponder,
          QuestionMessageResponder,
          AnonymousMessageResponder,
          GreetingMessageResponder,
          MemoMessageResponder
      ].each do |klass|
        expect(klass).to receive_message_chain(:from_dm, :respond).with(dm).with(no_args)
      end
      expect(worker).to receive(:process_schedule_tweets).with(dm)
      expect(SendReceivedMessageWorker).to receive(:perform_async).with(dm.sender_id, dm_id: dm.id, text: dm.text)
      expect(SendReceivedMediaToSlackWorker).to receive(:perform_async).with(dm.to_json)
      subject
    end
  end

  describe '#process_message_from_egotter' do
    let(:dm) { double('dm', recipient_id: 'recipient_id', id: 'id', text: 'text') }
    subject { worker.send(:process_message_from_egotter, dm) }

    it do
      expect(SendSentMessageWorker).to receive(:perform_async).with(dm.recipient_id, dm_id: dm.id, text: dm.text)
      subject
    end
  end

  describe '#sent_from_user?' do
    let(:dm) { double('dm', id: 1, sender_id: 1, text: text) }
    subject { worker.send(:sent_from_user?, dm) }

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
    subject { worker.send(:sent_from_egotter?, dm) }

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
