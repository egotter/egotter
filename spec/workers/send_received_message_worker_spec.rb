require 'rails_helper'

RSpec.describe SendReceivedMessageWorker do
  let(:worker) { described_class.new }

  describe '#ignore?' do
    [
        I18n.t('quick_replies.continue.label'),
        I18n.t('quick_replies.all_report.stop_label'),
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
        subject { worker.ignore?(text) }
        it { is_expected.to be_truthy }
      end
    end

    [
        'ありがとう',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        subject { worker.ignore?(text) }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#send_message' do
    let(:uid) { 1 }
    let(:screen_name) { 'name' }
    let(:text) { 'text' }
    let(:client) { double('client') }
    subject { worker.send(:send_message, uid, text) }
    before do
      allow(SlackBotClient).to receive(:channel).with('messages_received').and_return(client)
    end

    context 'User is found' do
      before { create(:twitter_db_user, uid: uid, screen_name: screen_name, profile_image_url_https: 'https://example.com/image.jpg') }
      it do
        expect(client).to receive(:post_context_message).with("#{uid} #{screen_name} #{text}", screen_name, instance_of(String), [])
        subject
      end
    end

    context 'User is NOT found' do
      it do
        expect(client).to receive(:post_message).with("#{uid} #{text}")
        subject
      end
    end
  end
end
