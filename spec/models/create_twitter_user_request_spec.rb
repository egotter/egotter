require 'rails_helper'

RSpec.describe CreateTwitterUserRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) do
    described_class.create(
        requested_by: 'test',
        session_id: 'session_id',
        user_id: user.id,
        uid: 1,
        ahoy_visit_id: 1)
  end

  describe 'perform!' do
    subject { request.perform!('context') }

    it do
      expect(request).to receive(:validate_request!)
      expect(request).to receive(:build_twitter_user).with('context').and_return(['twitter_user', 'relations'])
      expect(request).to receive(:validate_twitter_user!).with('twitter_user')
      expect(request).to receive(:assemble_twitter_user).with('twitter_user', 'relations')
      expect(request).to receive(:save_twitter_user).with('twitter_user')
      is_expected.to eq('twitter_user')
    end
  end

  describe 'validate_request!' do
    subject { request.validate_request! }

    before do
      allow(request).to receive(:user).and_return(user)
    end

    context 'finished? returns true' do
      before { allow(request).to receive(:finished?).and_return(true) }
      it { expect { subject }.to raise_error(described_class::AlreadyFinished) }
    end

    context 'unauthorized? returns true' do
      before { allow(user).to receive(:unauthorized?).and_return(true) }
      it { expect { subject }.to raise_error(described_class::Unauthorized) }
    end

    context 'too_short_create_interval? returns true' do
      before { allow(TwitterUser).to receive_message_chain(:latest_by, :too_short_create_interval?).with(uid: 1).with(no_args).and_return(true) }
      it { expect { subject }.to raise_error(described_class::TooShortCreateInterval) }
    end
  end

  describe '#build_twitter_user' do
    let(:relations_result) { {friend_ids: 'ids1', follower_ids: 'ids2'} }
    subject { request.build_twitter_user('context') }

    it do
      expect(request).to receive(:fetch_user).and_return('fetch_user')
      expect(request).to receive(:build_twitter_user_by).with('fetch_user').and_return('twitter_user')
      expect(request).to receive(:fetch_relations).with('twitter_user', 'context').and_return(relations_result)
      expect(request).to receive(:attach_friend_uids).with('twitter_user', 'ids1')
      expect(request).to receive(:attach_follower_uids).with('twitter_user', 'ids2')
      is_expected.to eq(['twitter_user', relations_result])
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
    let(:twitter_user) { build(:twitter_user) }
    subject { request.validate_twitter_user!(twitter_user) }

    context 'twitter_user is persisted' do
      before { allow(TwitterUser).to receive(:exists?).with(uid: request.uid).and_return(true) }

      context 'no_need_to_import_friendships? returns true' do
        before { allow(twitter_user).to receive(:no_need_to_import_friendships?).and_return(true) }
        it { expect { subject }.to raise_error(described_class::TooManyFriends) }
      end

      context 'diff_values_empty? returns true' do
        before { allow(request).to receive(:diff_values_empty?).with(twitter_user).and_return(true) }
        it { expect { subject }.to raise_error(described_class::NotChanged) }
      end

      context 'else' do
        before { allow(request).to receive(:diff_values_empty?).with(twitter_user).and_return(false) }
        it { expect { subject }.not_to raise_error }
      end
    end

    context 'twitter_user is not persisted' do
      before { allow(TwitterUser).to receive(:exists?).with(uid: request.uid).and_return(false) }
      it { expect { subject }.not_to raise_error }
    end
  end

  describe '#assemble_twitter_user' do
    let(:twitter_user) { build(:twitter_user) }
    let(:relations) { {user_timeline: 'ut', mentions_timeline: 'mt', search: 's', favorites: 'f'} }
    subject { request.assemble_twitter_user(twitter_user, relations) }
    it do
      expect(request).to receive(:attach_user_timeline).with(twitter_user, 'ut')
      expect(request).to receive(:attach_mentions_timeline).with(twitter_user, 'mt', 's')
      expect(request).to receive(:attach_favorite_tweets).with(twitter_user, 'f')
      subject
      expect(twitter_user).to satisfy { |result| result.user_id == user.id }
    end
  end

  describe '#save_twitter_user' do
    let(:twitter_user) { build(:twitter_user, id: 1) }
    subject { request.save_twitter_user(twitter_user) }
    it do
      expect(twitter_user).to receive(:save!)
      expect(request).to receive(:update).with(twitter_user_id: 1)
      subject
    end
  end

  describe '#fetch_user' do
    let(:client) { double('client') }
    subject { request.fetch_user }
    before { allow(request).to receive(:client).and_return(client) }
    it do
      expect(client).to receive(:user).with(request.uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#build_twitter_user_by' do
    subject { request.build_twitter_user_by('user') }
    it do
      expect(TwitterUser).to receive(:build_by).with(user: 'user').and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#fetch_relations' do
    subject { request.fetch_relations('twitter_user', 'context') }
    it do
      expect(TwitterUserFetcher).to receive_message_chain(:new, :fetch).
          with(twitter_user: 'twitter_user', login_user: 'user', context: 'context').with(no_args).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#attach_friend_uids' do
    let(:twitter_user) { instance_double(TwitterUser) }
    subject { request.attach_friend_uids(twitter_user, 'uids') }
    it do
      expect(twitter_user).to receive(:attach_friend_uids).with('uids').and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#attach_follower_uids' do
    let(:twitter_user) { instance_double(TwitterUser) }
    subject { request.attach_follower_uids(twitter_user, 'uids') }
    it do
      expect(twitter_user).to receive(:attach_follower_uids).with('uids').and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#attach_user_timeline' do
    let(:twitter_user) { instance_double(TwitterUser) }
    subject { request.attach_user_timeline(twitter_user, 'tweets') }
    it do
      expect(twitter_user).to receive(:attach_user_timeline).with('tweets').and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#attach_mentions_timeline' do
    let(:twitter_user) { instance_double(TwitterUser) }
    subject { request.attach_mentions_timeline(twitter_user, 'tweets', 'search_result') }
    it do
      expect(twitter_user).to receive(:attach_mentions_timeline).with('tweets', 'search_result').and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#attach_favorite_tweets' do
    let(:twitter_user) { instance_double(TwitterUser) }
    subject { request.attach_favorite_tweets(twitter_user, 'tweets') }
    it do
      expect(twitter_user).to receive(:attach_favorite_tweets).with('tweets').and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#diff_values_empty?' do
    subject { request.diff_values_empty?('twitter_user') }
    it do
      expect(TwitterUser).to receive_message_chain(:latest_by, :diff, :empty?).
          with(uid: request.uid).with('twitter_user').with(no_args).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#exception_handler' do
    let(:error) { RuntimeError.new }
    subject { request.exception_handler(error) }

    context 'error is retryable' do
      before { allow(ServiceStatus).to receive(:retryable_error?).with(error).and_return(true) }
      it { expect { subject }.not_to raise_error }
    end

    context 'retry is repeated' do
      before { allow(ServiceStatus).to receive(:retryable_error?).with(error).and_return(true) }
      it { expect { 4.times { request.exception_handler(error) } }.to raise_error(described_class::RetryExhausted) }
    end

    [described_class::TooShortCreateInterval, described_class::TooManyFriends, described_class::NotChanged].each do |klass|
      context "#{klass} is raised" do
        let(:error) { klass.new }
        it { expect { subject }.to raise_error(klass) }
      end
    end

    context 'token is invalid' do
      before { allow(AccountStatus).to receive(:unauthorized?).with(error).and_return(true) }
      it { expect { subject }.to raise_error(described_class::Unauthorized) }
    end

    context 'user is protected' do
      before { allow(AccountStatus).to receive(:protected?).with(error).and_return(true) }
      it { expect { subject }.to raise_error(described_class::Protected) }
    end

    context 'admin is blocked' do
      before { allow(AccountStatus).to receive(:blocked?).with(error).and_return(true) }
      it { expect { subject }.to raise_error(described_class::Blocked) }
    end

    context 'user is locked' do
      before { allow(AccountStatus).to receive(:temporarily_locked?).with(error).and_return(true) }
      it { expect { subject }.to raise_error(described_class::TemporarilyLocked) }
    end

    context 'else' do
      it { expect { subject }.to raise_error(described_class::Unknown) }
    end
  end
end
