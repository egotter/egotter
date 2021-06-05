require 'rails_helper'

RSpec.describe CreateTwitterUserRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) do
    described_class.create(
        requested_by: 'test',
        session_id: 'session_id',
        user: user,
        uid: 1,
        ahoy_visit_id: 1)
  end

  describe '.too_short_request_interval?' do
    subject { described_class.too_short_request_interval?(1) }
    it { is_expected.to be_falsey }

    context 'the creation request is has already been created' do
      before { request }
      it { is_expected.to be_truthy }
    end
  end

  describe 'perform!' do
    let(:snapshot) { TwitterSnapshot.new({}) }
    subject { request.perform!('context') }

    it do
      expect(request).to receive(:validate_request!)
      expect(request).to receive(:validate_creation_interval!).exactly(3).times
      expect(request).to receive(:build_snapshot).with('context').and_return([snapshot, 'relations'])
      expect(request).to receive(:validate_twitter_user!).with(snapshot)
      expect(SearchLimitation).to receive(:warn_limit?).with(snapshot)
      expect(request).to receive(:assemble_twitter_user).with(snapshot, 'relations')
      expect(request).to receive(:save_twitter_user).with(snapshot).and_return('twitter_user')
      is_expected.to eq('twitter_user')
    end
  end

  describe 'validate_request!' do
    subject { request.send(:validate_request!) }

    before do
      allow(request).to receive(:user).and_return(user)
    end

    context 'finished? returns true' do
      before { allow(request).to receive(:finished?).and_return(true) }
      it { expect { subject }.to raise_error(described_class::AlreadyFinished) }
    end

    context 'unauthorized? returns true' do
      before { allow(user).to receive(:authorized?).and_return(false) }
      it { expect { subject }.to raise_error(described_class::Unauthorized) }
    end
  end

  describe 'validate_creation_interval!' do
    subject { request.send(:validate_creation_interval!) }

    before do
      allow(request).to receive(:user).and_return(user)
    end

    context 'too_short_create_interval? returns true' do
      before { allow(TwitterUser).to receive(:too_short_create_interval?).with(1).and_return(true) }
      it { expect { subject }.to raise_error(described_class::TooShortCreateInterval) }
    end
  end

  describe '#build_snapshot' do
    let(:snapshot) { TwitterSnapshot.new(nil) }
    let(:fetched_user) { {id: 1, screen_name: 'sn'} }
    let(:relations_result) { {friend_ids: 'ids1', follower_ids: 'ids2'} }
    subject { request.send(:build_snapshot, 'context') }

    it do
      expect(request).to receive(:fetch_user).and_return(fetched_user)
      expect(TwitterSnapshot).to receive(:new).with(fetched_user).and_return(snapshot)
      expect(request).to receive(:fetch_relations).with(snapshot, 'context').and_return(relations_result)
      expect(snapshot).to receive(:friend_uids=).with('ids1')
      expect(snapshot).to receive(:follower_uids=).with('ids2')
      is_expected.to eq([snapshot, relations_result])
    end

    context 'exception is raised' do
      let(:error) { RuntimeError.new }
      before { allow(request).to receive(:fetch_user).and_raise(error) }
      it do
        expect(request).to receive(:exception_handler).with(error).and_call_original
        expect { subject }.to raise_error(described_class::Unknown)
      end
    end
  end

  describe '#validate_twitter_user!' do
    let(:twitter_user) { TwitterSnapshot.new({friends_count: 100, followers_count: 200}) }
    subject { request.send(:validate_twitter_user!, twitter_user) }
    before do
      twitter_user.friend_uids = [1, 2]
      twitter_user.follower_uids = [3, 4]
    end

    shared_context 'twitter_user is persisted' do
      before { allow(TwitterUser).to receive(:exists?).with(uid: request.uid).and_return(true) }
    end

    context 'there is no friends and followers' do
      include_context 'twitter_user is persisted'
      before { allow(twitter_user).to receive(:too_little_friends?).and_return(true) }
      it { expect { subject }.to raise_error(described_class::TooLittleFriends) }
    end

    context 'there are too many friends and followers' do
      include_context 'twitter_user is persisted'
      before { allow(SearchLimitation).to receive(:hard_limited?).with(twitter_user).and_return(true) }
      it { expect { subject }.to raise_error(described_class::TooManyFriends) }
    end

    context 'no_need_to_import_friendships? returns true' do
      include_context 'twitter_user is persisted'
      before { allow(twitter_user).to receive(:no_need_to_import_friendships?).and_return(true) }
      it { expect { subject }.to raise_error(described_class::TooManyFriends) }
    end

    context 'diff_values_empty? returns true' do
      include_context 'twitter_user is persisted'
      before { allow(request).to receive(:diff_values_empty?).with(twitter_user).and_return(true) }
      it { expect { subject }.to raise_error(described_class::NotChanged) }
    end

    context 'else' do
      include_context 'twitter_user is persisted'
      before { allow(request).to receive(:diff_values_empty?).with(twitter_user).and_return(false) }
      it { expect { subject }.not_to raise_error }
    end

    context 'twitter_user is not persisted' do
      before { allow(TwitterUser).to receive(:exists?).with(uid: request.uid).and_return(false) }
      it { expect { subject }.not_to raise_error }
    end
  end

  describe '#assemble_twitter_user' do
    let(:twitter_user) { TwitterSnapshot.new(nil) }
    let(:relations) { {user_timeline: 'ut', mentions_timeline: 'mt', search: 's', favorites: 'f'} }
    subject { request.send(:assemble_twitter_user, twitter_user, relations) }
    before do
      allow(twitter_user).to receive(:screen_name).and_return('sn')
      allow(request).to receive(:collect_mention_tweets).with('mt', 's', 'sn').and_return('mt')
    end
    it do
      expect(twitter_user).to receive(:user_timeline=).with('ut')
      expect(twitter_user).to receive(:mention_tweets=).with('mt')
      expect(twitter_user).to receive(:favorite_tweets=).with('f')
      subject
      expect(twitter_user).to satisfy { |result| result.user_id == user.id }
    end
  end

  describe '#save_twitter_user' do
    let(:snapshot) { TwitterSnapshot.new(nil) }
    let(:twitter_user) { TwitterUser.new(id: 1) }
    subject { request.send(:save_twitter_user, snapshot) }
    it do
      expect(snapshot).to receive(:copy).and_return(twitter_user)
      expect(twitter_user).to receive(:perform_before_transaction!)
      expect(twitter_user).to receive(:save!)
      expect(request).to receive(:update).with(twitter_user_id: 1)
      is_expected.to eq(twitter_user)
    end
  end

  describe '#fetch_user' do
    let(:client) { double('client') }
    subject { request.send(:fetch_user) }
    before { allow(request).to receive(:client).and_return(client) }
    it do
      expect(client).to receive(:user).with(request.uid).and_return('result')
      is_expected.to eq('result')
    end

    [
        Twitter::Error::Forbidden.new('User has been suspended.'),
        Twitter::Error::NotFound.new('User not found.')
    ].each do |error_value|
      context "#{error_value} is raised" do
        let(:error) { error_value }
        before { allow(client).to receive(:user).with(request.uid).and_raise(error) }
        it { expect { subject }.to raise_error(described_class::Error) }
      end
    end
  end

  describe '#fetch_relations' do
    let(:snapshot) { create(:twitter_user) }
    let(:client) { 'client' }
    let(:context) { 'context' }
    let(:fetcher) { double('fetcher') }
    subject { request.send(:fetch_relations, snapshot, context) }
    before { allow(user).to receive(:api_client).with(cache_store: :null_store).and_return(client) }

    it do
      expect(TwitterUserFetcher).to receive(:new).
          with(client, snapshot.uid, snapshot.screen_name, true, false, false).and_return(fetcher)
      expect(fetcher).to receive(:fetch_in_threads).and_return('result')
      is_expected.to eq('result')
    end

    context 'user is nil' do
      before { allow(request).to receive(:user).and_return(nil) }
      it do
        expect(Bot).to receive(:api_client).with(cache_store: :null_store).and_return(client)
        expect(TwitterUserFetcher).to receive(:new).with(any_args).and_return(fetcher)
        expect(fetcher).to receive(:fetch_in_threads).and_return('result')
        is_expected.to eq('result')
      end
    end
  end

  describe '#diff_values_empty?' do
    subject { request.send(:diff_values_empty?, 'twitter_user') }
    it do
      expect(TwitterUser).to receive_message_chain(:latest_by, :diff, :empty?).
          with(uid: request.uid).with('twitter_user').with(no_args).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#exception_handler' do
    let(:error) { RuntimeError.new }
    subject { request.send(:exception_handler, error) }

    context 'error is retryable' do
      before { allow(ServiceStatus).to receive(:retryable_error?).with(error).and_return(true) }
      it { expect { subject }.not_to raise_error }
    end

    context 'retry is repeated' do
      before { allow(ServiceStatus).to receive(:retryable_error?).with(error).and_return(true) }
      it { expect { 4.times { request.send(:exception_handler, error) } }.to raise_error(described_class::RetryExhausted) }
    end

    [described_class::TooShortCreateInterval, described_class::TooManyFriends, described_class::NotChanged].each do |klass|
      context "#{klass} is raised" do
        let(:error) { klass.new }
        it { expect { subject }.to raise_error(klass) }
      end
    end

    context 'token is invalid' do
      before { allow(TwitterApiStatus).to receive(:unauthorized?).with(error).and_return(true) }
      it { expect { subject }.to raise_error(described_class::Unauthorized) }
    end

    context 'user is protected' do
      before { allow(TwitterApiStatus).to receive(:protected?).with(error).and_return(true) }
      it { expect { subject }.to raise_error(described_class::Protected) }
    end

    context 'admin is blocked' do
      before { allow(TwitterApiStatus).to receive(:blocked?).with(error).and_return(true) }
      it { expect { subject }.to raise_error(described_class::Blocked) }
    end

    context 'user is locked' do
      before { allow(TwitterApiStatus).to receive(:temporarily_locked?).with(error).and_return(true) }
      it { expect { subject }.to raise_error(described_class::TemporarilyLocked) }
    end

    context 'rate limit exceeded' do
      let(:error) { Twitter::Error::TooManyRequests.new }
      before { allow(TwitterApiStatus).to receive(:too_many_requests?).with(error).and_return(true) }
      it { expect { subject }.to raise_error(described_class::TooManyRequests) }
    end

    context 'else' do
      it { expect { subject }.to raise_error(described_class::Unknown) }
    end
  end
end
