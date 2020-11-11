require 'rails_helper'

RSpec.describe SendReceivedMessageWorker do
  let(:worker) { described_class.new }

  describe '#static_message?' do
    [
        I18n.t('quick_replies.continue.label'),
        'リムられ通知',
        'リムられ通知 今すぐ',
        'リムられ通知送信',
        'リムられ',
        '通知',
        '再開',
        '継続',
        '今すぐ',
        'あ',
        'は',
        'り',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        subject { worker.static_message?(text) }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#send_message_to_slack' do
    let(:uid) { 1 }
    let(:name) { 'name' }
    subject { worker.send_message_to_slack(uid, 'text') }
    before do
      allow(described_class::Message).to receive_message_chain(:new, :to_s).with(uid, name).with(no_args).and_return('message')
      allow(worker).to receive(:recently_tweets_deleted_user?).with(uid).and_return(false)
    end
    it do
      expect(SlackClient).to receive_message_chain(:channel, :send_message).with('received_messages').with('message')
      subject
    end
  end

  describe '#recently_tweets_deleted_user?' do
    context 'user is not found' do
      subject { worker.recently_tweets_deleted_user?(1) }
      it { is_expected.to be_falsey }
    end

    context 'request is not found' do
      let(:user) { create(:user) }
      subject { worker.recently_tweets_deleted_user?(user.uid) }
      it { is_expected.to be_falsey }
    end

    context 'request is found' do
      let(:user) { create(:user) }
      subject { worker.recently_tweets_deleted_user?(user.uid) }
      before { DeleteTweetsRequest.create!(user_id: user.id) }
      it { is_expected.to be_truthy }
    end
  end
end
