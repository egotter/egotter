require 'rails_helper'

describe DeleteTweetsConcern, type: :controller do
  controller ApplicationController do
    include DeleteTweetsConcern
  end

  let(:user) { create(:user) }

  before do
    allow(User).to receive(:find_by).with(uid: user.uid).and_return(user)
  end

  describe '#delete_tweets_questioned?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:delete_tweets_questioned?, dm.text) }

    [
        '削除',
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
    subject { controller.send(:answer_delete_tweets_question, user.uid) }

    it do
      expect(CreateDeleteTweetsQuestionedMessageWorker).to receive(:perform_async).with(user.uid)
      subject
    end
  end
end
