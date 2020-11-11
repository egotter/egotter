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

  describe '#send_message' do
    let(:uid) { 1 }
    let(:name) { 'name' }
    let(:client1) { double('client1') }
    let(:client2) { double('client2') }
    subject { worker.send(:send_message, uid, 'text') }
    before do
      allow(SlackClient).to receive(:channel).with('received_messages').and_return(client1)
      allow(SlackClient).to receive(:channel).with('delete_tweets').and_return(client2)
      allow(worker).to receive(:recently_tweets_deleted_user?).with(uid).and_return(true)
    end
    it do
      expect(client1).to receive(:send_context_message).with(any_args)
      expect(client2).to receive(:send_context_message).with(any_args)
      subject
    end
  end

  describe '#recently_tweets_deleted_user?' do
    let(:user) { create(:user) }
    subject { worker.send(:recently_tweets_deleted_user?, user.uid) }

    context 'user is not found' do
      before { allow(User).to receive(:find_by).with(uid: user.uid).and_return(nil) }
      it { is_expected.to be_falsey }
    end

    context 'request is not found' do
      before { allow(User).to receive(:find_by).with(uid: user.uid).and_return(user) }
      it { is_expected.to be_falsey }
    end

    context 'request is found' do
      before do
        allow(User).to receive(:find_by).with(uid: user.uid).and_return(user)
        DeleteTweetsRequest.create!(user_id: user.id)
      end
      it { is_expected.to be_truthy }
    end
  end
end
