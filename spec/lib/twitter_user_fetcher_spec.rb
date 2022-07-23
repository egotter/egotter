require 'rails_helper'

RSpec.describe TwitterUserFetcher do
  let(:user) { create(:user) }
  let(:uid) { user.uid }
  let(:screen_name) { user.screen_name }
  let(:passed_client) { double('passed_client', twitter: 'twitter') }
  let(:client) { double('client') }
  let(:fetch_friends) { true }
  let(:search_for_yourself) { true }
  let(:reporting) { false }
  let(:instance) { described_class.new(passed_client, uid, screen_name, fetch_friends, search_for_yourself, reporting) }

  before do
    allow(described_class::ClientWrapper).to receive(:new).with(passed_client, 'twitter').and_return(client)
  end

  describe '#fetch' do
    subject { instance.fetch }
    it do
      expect(instance).to receive(:fetch_in_threads)
      subject
    end

    context 'ThreadError is raised' do
      let(:error) { ThreadError.new("can't alloc thread") }
      before { allow(instance).to receive(:fetch_in_threads).and_raise(error) }
      it do
        expect(instance).to receive(:fetch_without_threads)
        subject
      end
    end
  end

  describe '#fetch_without_threads' do
    subject { instance.fetch_without_threads }

    it do
      expect(client).to receive(:friend_ids).with(uid)
      expect(client).to receive(:follower_ids).with(uid)
      expect(client).to receive(:user_timeline).with(uid)
      expect(client).to receive(:mentions_timeline)
      expect(client).to receive(:favorites).with(uid)
      is_expected.to be_truthy
    end

    context 'fetch_friends is false' do
      let(:fetch_friends) { false }
      it do
        expect(client).not_to receive(:friend_ids)
        expect(client).not_to receive(:follower_ids)
        expect(client).to receive(:user_timeline).with(uid)
        expect(client).to receive(:mentions_timeline)
        expect(client).to receive(:favorites).with(uid)
        is_expected.to be_truthy
      end
    end

    context 'search_for_yourself is false' do
      let(:search_for_yourself) { false }
      it do
        expect(client).to receive(:friend_ids).with(uid)
        expect(client).to receive(:follower_ids).with(uid)
        expect(client).to receive(:user_timeline).with(uid)
        expect(client).to receive(:search).with("@#{screen_name}")
        expect(client).to receive(:favorites).with(uid)
        is_expected.to be_truthy
      end
    end

    context 'reporting is true' do
      let(:reporting) { true }
      it do
        expect(client).to receive(:friend_ids).with(uid)
        expect(client).to receive(:follower_ids).with(uid)
        expect(client).not_to receive(:user_timeline)
        expect(client).to receive(:mentions_timeline)
        expect(client).to receive(:favorites).with(uid)
        is_expected.to be_truthy
      end
    end
  end

  describe '#fetch_in_threads' do
    subject { instance.fetch_in_threads }
    it do
      expect(client).to receive(:friend_ids).with(uid)
      expect(client).to receive(:follower_ids).with(uid)
      expect(client).to receive(:user_timeline).with(uid)
      expect(client).to receive(:mentions_timeline)
      expect(client).to receive(:favorites).with(uid)
      is_expected.to be_truthy
    end
  end
end

RSpec.describe TwitterUserFetcher::ClientWrapper do
  let(:twitter) { double('twitter') }
  let(:client) { double('client') }
  let(:instance) { described_class.new(client, twitter) }

  describe 'friend_ids' do
    subject { instance.friend_ids(1) }
    it do
      expect(twitter).to receive(:friend_ids).with(1, {count: 5000, cursor: -1})
      subject
    end
  end

  describe 'follower_ids' do
    subject { instance.follower_ids(1) }
    it do
      expect(twitter).to receive(:follower_ids).with(1, {count: 5000, cursor: -1})
      subject
    end
  end

  describe 'user_timeline' do
    subject { instance.user_timeline(1) }
    it do
      expect(client).to receive(:user_timeline).with(1, include_rts: false)
      subject
    end

    context 'An exception is raised' do
      let(:error) { RuntimeError.new }
      before do
        allow(client).to receive(:user_timeline).and_raise(error)
        allow(TwitterApiStatus).to receive(:too_many_requests?).with(error).and_return(true)
      end
      it { expect { subject }.not_to raise_error }
    end
  end

  describe 'mentions_timeline' do
    subject { instance.mentions_timeline }
    it do
      expect(client).to receive(:mentions_timeline)
      subject
    end

    context 'An exception is raised' do
      let(:error) { RuntimeError.new }
      before do
        allow(client).to receive(:mentions_timeline).and_raise(error)
        allow(TwitterApiStatus).to receive(:too_many_requests?).with(error).and_return(true)
      end
      it { expect { subject }.not_to raise_error }
    end
  end

  describe 'search' do
    subject { instance.search('word') }
    it do
      expect(client).to receive(:search).with('word')
      subject
    end

    context 'An exception is raised' do
      let(:error) { RuntimeError.new }
      before do
        allow(client).to receive(:search).and_raise(error)
        allow(TwitterApiStatus).to receive(:too_many_requests?).with(error).and_return(true)
      end
      it { expect { subject }.not_to raise_error }
    end
  end

  describe 'favorites' do
    subject { instance.favorites(1) }
    it do
      expect(client).to receive(:favorites).with(1)
      subject
    end

    context 'An exception is raised' do
      let(:error) { RuntimeError.new }
      before do
        allow(client).to receive(:favorites).and_raise(error)
        allow(TwitterApiStatus).to receive(:too_many_requests?).with(error).and_return(true)
      end
      it { expect { subject }.not_to raise_error }
    end
  end
end
