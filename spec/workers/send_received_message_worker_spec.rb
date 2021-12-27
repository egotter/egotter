require 'rails_helper'

RSpec.describe SendReceivedMessageWorker do
  let(:worker) { described_class.new }

  describe '#dont_send_message?' do
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
        subject { worker.dont_send_message?(text) }
        it { is_expected.to be_truthy }
      end
    end

    [
        'ありがとう',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        subject { worker.dont_send_message?(text) }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#send_message' do
    let(:uid) { 1 }
    let(:name) { 'name' }
    let(:client) { double('client') }
    subject { worker.send(:send_message, uid, 'text') }
    before do
      allow(SlackBotClient).to receive(:channel).with('messages_received').and_return(client)
    end
    it do
      expect(client).to receive(:post_context_message).with(any_args)
      subject
    end
  end
end
