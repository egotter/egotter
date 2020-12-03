require 'rails_helper'

describe DeleteTweetsConcern, type: :controller do
  let(:instance) { Object.new }

  before do
    instance.extend DeleteTweetsConcern
  end

  describe '#process_delete_tweets' do
    let(:dm) { double('dm', sender_id: 1, text: 'text') }
    subject { instance.process_delete_tweets(dm) }

    it { is_expected.to be_falsey }

    context '#delete_tweets_questioned? returns true' do
      before { allow(instance).to receive(:delete_tweets_questioned?).with(dm.text).and_return(true) }
      it do
        expect(instance).to receive(:answer_delete_tweets_question).with(dm.sender_id)
        is_expected.to be_truthy
      end
    end
  end

  describe '#delete_tweets_questioned?' do
    subject { instance.delete_tweets_questioned?(text) }

    [
        '削除',
        '消去',
        '全消し',
        'ツイ消し',
        'クリーナー',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#answer_delete_tweets_question' do
    let(:uid) { 1 }
    subject { instance.answer_delete_tweets_question(uid) }

    it do
      expect(CreateDeleteTweetsQuestionedMessageWorker).to receive(:perform_async).with(uid)
      subject
    end
  end
end
