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
  let(:client) { double('Client') }

  before { allow(request).to receive(:client).and_return(client) }

  shared_context 'When user authorized' do
    before { user.update(authorized: true) }
  end

  describe '#perform!' do
    include_context 'When user authorized'
  end

  describe '#build_twitter_user' do
    let(:fetched_user) { {id: 1, screen_name: 'sn', friends_count: 2, followers_count: 3} }
    let(:context) {'context'}
    let(:snapshot) { instance_double(TwitterUserSnapshot) }
    let(:fetcher) { instance_double(TwitterUserFetcher::Fetcher) }
    let(:resources) do
      {
          friend_ids: 'friend_ids',
          follower_ids: 'follower_ids',
          user_timeline: 'user_timeline',
          favorites: 'favorites',
          mentions_timeline: 'mentions_timeline',
          search: 'search',
      }
    end
    subject { request.build_twitter_user(context) }

    before do
      allow(request).to receive(:fetch_user).and_return(fetched_user)
      allow(fetcher).to receive(:fetch).and_return(resources)
    end

    it do
      expect(TwitterUserSnapshot).to receive(:initialize_by).with(user: fetched_user).and_return(snapshot)
      expect(request).to receive(:dispatch_resources_fetcher).with(instance_of(TwitterUserSnapshot), context).and_return(fetcher)

      expect(snapshot).to receive(:build_friends).with('friend_ids').and_return(snapshot)
      expect(snapshot).to receive(build_followers)
    end

    context 'The token is invalid' do
      before { allow(request).to receive(:fetch_user).and_raise(Twitter::Error::Unauthorized, 'Invalid or expired token.') }
      it { expect { subject }.to raise_error(described_class::Unauthorized) }
    end

    context 'The user is protected' do
      before { allow(request).to receive(:fetch_user).and_raise(Twitter::Error::Unauthorized, 'Not authorized.') }
      it { expect { subject }.to raise_error(described_class::Protected) }
    end

    context '#fetch_user raises Twitter::Error::InternalServerError' do
      before { allow(request).to receive(:fetch_user).and_raise(Twitter::Error::InternalServerError, 'Internal error') }
      it { expect { subject }.to raise_error(described_class::InternalServerError) }
    end

    context '#fetch_user raises Twitter::Error::ServiceUnavailable' do
      before { allow(request).to receive(:fetch_user).and_raise(Twitter::Error::ServiceUnavailable, 'Over capacity') }
      it { expect { subject }.to raise_error(described_class::ServiceUnavailable) }
    end

    context '#fetch_user raises Twitter::Error::Unauthorized(blocked)' do
      before { allow(request).to receive(:fetch_user).and_raise(Twitter::Error::Unauthorized, "You have been blocked from viewing this user's profile.") }
      it { expect { subject }.to raise_error(described_class::Blocked) }
    end
  end

  describe '#dispatch_exception' do

  end

  describe '#fetch_user' do
    subject { request.fetch_user }
    before do
      allow(client).to receive(:user).with(1).and_raise(Twitter::Error::Unauthorized, 'Invalid or expired token.')
    end

    it { expect { subject }.to raise_error(described_class::Unauthorized) }
  end
end
