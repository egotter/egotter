require 'rails_helper'

RSpec.describe TrendSearcher::Tweet, type: :model do
  describe '.from_hash' do
    let(:attrs) do
      {
          id: 'tweet_id',
          text: 'text',
          user: {
              id: 'user_id',
              screen_name: 'screen_name'
          },
          created_at: '2021-01-01 01:00',
      }
    end
    subject { described_class.from_hash(attrs) }

    before do
      attrs[:retweeted_status] = attrs.dup
    end

    it do
      instance = subject
      [instance, instance.retweeted_status].each do |tweet|
        expect(tweet.tweet_id).to eq('tweet_id')
        expect(tweet.text).to eq('text')
        expect(tweet.uid).to eq('user_id')
        expect(tweet.screen_name).to eq('screen_name')
        expect(tweet.tweeted_at.to_i).to eq(Time.zone.parse(attrs[:created_at]).to_i)
      end
    end
  end
end
