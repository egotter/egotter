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
end
