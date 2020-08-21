require 'rails_helper'

RSpec.describe TwitterHelper, type: :helper do
  describe '#user_url' do
    subject { helper.user_url('name') }
    it { is_expected.to eq('https://twitter.com/name') }
  end

  describe '#direct_message_url' do
    subject { helper.direct_message_url(1) }
    it { is_expected.to eq("https://twitter.com/messages/compose?recipient_id=1") }

    context 'text is passed' do
      subject { helper.direct_message_url(1, 'a b') }
      it { is_expected.to eq("https://twitter.com/messages/compose?recipient_id=1&text=a%20b") }
    end
  end

  describe '#follow_intent_url' do
    subject { helper.follow_intent_url('name') }
    it { is_expected.to eq("https://twitter.com/intent/follow?screen_name=name") }
  end

  describe '#user_link' do
    let(:options) { {target: '_blank', rel: 'nofollow'} }
    subject { helper.user_link('name') }
    before do
      allow(helper).to receive(:user_url).with('name').and_return('user_url')
      allow(helper).to receive(:mention_name).with('name').and_return('@name')
    end
    it do
      expect(helper).to receive(:link_to).with('@name', 'user_url', options)
      subject
    end

    context 'block is passed' do
      let(:block) { Proc.new {} }
      subject { helper.user_link('name', &block) }
      it do
        expect(helper).to receive(:link_to).with('user_url', options) do |&blk|
          expect(blk).to be(block)
        end
        subject
      end
    end
  end

  describe '#tweet_url' do
    subject { helper.tweet_url('name', 1) }
    it { is_expected.to eq("https://twitter.com/name/status/1") }
  end

  describe '#tweet_link' do
    let(:user) { double('User', screen_name: 'name') }
    let(:tweet) { double('Tweet', tweeted_at: Time.zone.now, tweet_id: 1, user: user) }
    subject { helper.tweet_link(tweet) }
    before do
      allow(helper).to receive(:time_ago_in_words).with(tweet.tweeted_at).and_return('time_ago')
      allow(helper).to receive(:tweet_url).with('name', 1).and_return('url')
    end
    it do
      expect(helper).to receive(:link_to).with('time_ago', 'url', {target: '_blank', rel: 'nofollow'})
      subject
    end
  end

  describe '#linkify' do
    subject { helper.linkify('Hello @name') }
    it { is_expected.to eq(%Q(Hello <a class="tweet-url username" href="https://egotter.com/timelines/name?via=link_by_linkify">@name</a>)) }
  end

  describe '#mention_name' do
    subject { helper.mention_name('name') }
    it { is_expected.to eq('@name') }
  end

  describe '#normal_icon_url' do
    let(:user) { double('User') }
    subject { helper.normal_icon_url(user) }
    it do
      expect(user).to receive_message_chain(:profile_image_url_https, :to_s)
      subject
    end
  end

  describe '#bigger_icon_url' do
    let(:user) { double('User') }
    subject { helper.bigger_icon_url(user) }
    before { allow(user).to receive(:profile_image_url_https).and_return('https://example.com/aaa_normal.jpg') }
    it { is_expected.to eq('https://example.com/aaa_bigger.jpg') }
  end
end
