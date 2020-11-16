require 'rails_helper'

describe ScheduleTweetsConcern do
  let(:instance) { Object.new }

  before do
    instance.extend ScheduleTweetsConcern
  end

  describe '#process_schedule_tweets' do
    let(:dm) { double('dm', sender_id: 1, text: 'text') }
    subject { instance.process_schedule_tweets(dm) }

    it { is_expected.to be_falsey }

    context '#schedule_tweets_questioned? returns true' do
      before { allow(instance).to receive(:schedule_tweets_questioned?).with(dm.text).and_return(true) }
      it do
        expect(instance).to receive(:answer_schedule_tweets_question).with(dm.sender_id)
        is_expected.to be_truthy
      end
    end
  end

  describe '#schedule_tweets_questioned?' do
    subject { instance.schedule_tweets_questioned?(text) }

    [
        '予約',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#answer_schedule_tweets_question' do
    let(:uid) { 1 }
    subject { instance.answer_schedule_tweets_question(uid) }

    it do
      expect(CreateScheduleTweetsQuestionedMessageWorker).to receive(:perform_async).with(uid)
      subject
    end
  end
end
