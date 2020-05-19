require 'rails_helper'

RSpec.describe PeriodicReport do
  let(:user) { create(:user, with_credential_token: true) }
  let(:request) { double('request', id: 1) }
  let(:start_date) { 1.day.ago }
  let(:end_date) { Time.zone.now }
  let(:unfriends) { %w(a b c) }

  describe '.periodic_message' do
    subject do
      described_class.periodic_message(
          user.id,
          request_id: request.id,
          start_date: start_date,
          end_date: end_date,
          unfriends: unfriends,
          unfollowers: unfollowers
      )
    end

    context 'unfollowers.size is greater than 1' do
      let(:unfollowers) { %w(x y z) }
      it { is_expected.to be_truthy }
    end

    context 'unfollowers.size is 1' do
      let(:unfollowers) { [] }
      it { is_expected.to be_truthy }
    end
  end

  describe '.periodic_push_message' do
    subject do
      described_class.periodic_push_message(
          user.id,
          request_id: request.id,
          start_date: start_date,
          end_date: end_date,
          unfriends: unfriends,
          unfollowers: unfollowers
      )
    end

    context 'unfollowers.size is greater than 1' do
      let(:unfollowers) { %w(x y z) }
      it { is_expected.to be_truthy }
    end

    context 'unfollowers.size is 1' do
      let(:unfollowers) { [] }
      it { is_expected.to be_truthy }
    end
  end

  describe '#send_direct_message' do
    let(:report) { described_class.new }
    let(:sender) { double('sender', uid: 1) }
    let(:recipient) { double('recipient', uid: 2) }
    subject { report.send_direct_message }

    before do
      allow(report).to receive(:user).and_return(user)
      allow(report).to receive(:report_sender).and_return(sender)
      allow(report).to receive(:report_recipient).and_return(recipient)
      allow(sender).to receive_message_chain(:api_client, :create_direct_message_event).with(anything).and_return('dm')
    end

    context 'send_remind_reply_message? returns true' do
      before { allow(report).to receive(:send_remind_reply_message?).with(sender).and_return(true) }
      it do
        expect(report).to receive(:send_remind_reply_message)
        subject
      end
    end
  end

  describe '#send_remind_reply_message?' do
    let(:report) { described_class.new }
    let(:sender) { double('sender', uid: 1) }
    subject { report.send_remind_reply_message?(sender) }

    before { allow(report).to receive(:user).and_return(user) }

    context 'sender.uid == egotter uid' do
      before do
        allow(sender).to receive(:uid).and_return(User::EGOTTER_UID)
        allow(GlobalDirectMessageReceivedFlag).to receive_message_chain(:new, :remaining).with(user.uid).and_return(ttl)
      end

      context 'remaining ttl is short' do
        let(:ttl) { 1.hour }
        it { is_expected.to be_truthy }
      end

      context 'remaining ttl is long' do
        let(:ttl) { 20.hours }
        it { is_expected.to be_falsey }
      end
    end

    context 'sender.uid != egotter uid' do
      it { is_expected.to be_truthy }
    end
  end

  describe '#send_remind_reply_message' do
    let(:report) { described_class.new }
    subject { report.send_remind_reply_message }

    before { allow(report).to receive(:user).and_return(user) }

    it do
      expect(described_class).to receive_message_chain(:remind_reply_message, :message).and_return('message')
      expect(described_class).to receive(:build_direct_message_event).with(user.uid, 'message').and_return('event')
      expect(User).to receive_message_chain(:egotter, :api_client, :create_direct_message_event).with(no_args).with(event: 'event')
      subject
    end
  end
end
