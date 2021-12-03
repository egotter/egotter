require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build(:user) }

  context 'validation' do
    it 'passes all' do
      expect(User.new.tap { |u| u.valid? }.errors[:uid].any?).to be_truthy
      expect(User.new(uid: -1).tap { |u| u.valid? }.errors[:uid].size).to eq(1)
      expect(User.new(uid: 1).tap { |u| u.valid? }.errors[:uid].size).to eq(0)

      expect(User.new.tap { |u| u.valid? }.errors[:screen_name].any?).to be_truthy
      expect(User.new(screen_name: '$sn').tap { |u| u.valid? }.errors[:screen_name].size).to eq(1)
      expect(User.new(screen_name: 'sn').tap { |u| u.valid? }.errors[:screen_name].size).to eq(0)

      # %i(secret token).each do |attr|
      #   expect(User.new.tap { |u| u.valid? }.errors[attr].size).to eq(1)
      # end
      # %i(secret token).product([nil, '']).each do |attr, value|
      #   expect(User.new(attr => value).tap { |u| u.valid? }.errors[attr].size).to eq(1)
      # end

      expect(User.new.tap { |u| u.valid? }.errors[:email].size).to eq(0)
      expect(User.new(email: nil).tap { |u| u.valid? }.errors[:email].size).to eq(1)
      expect(User.new(email: '').tap { |u| u.valid? }.errors[:email].size).to eq(0)
      expect(User.new(email: 'a@b.com').tap { |u| u.valid? }.errors[:email].size).to eq(0)
    end
  end

  describe '#expired_token?' do
    let(:user) { create(:user) }
    let(:client) { double('client') }
    subject { user.expired_token? }

    before do
      allow(user).to receive(:api_client).and_return(client)
    end

    context 'token is not expired' do
      before { allow(client).to receive(:verify_credentials).and_return(id: 1) }
      it { is_expected.to be_falsey }
    end

    context 'token is expired' do
      let(:error) { RuntimeError.new }
      before do
        allow(client).to receive(:verify_credentials).and_raise(error)
        allow(TwitterApiStatus).to receive(:invalid_or_expired_token?).with(error).and_return(true)
      end
      it { is_expected.to be_truthy }
    end

    context 'error is raised' do
      let(:error) { RuntimeError.new }
      before do
        allow(client).to receive(:verify_credentials).and_raise(error)
        allow(TwitterApiStatus).to receive(:invalid_or_expired_token?).with(error).and_return(false)
      end
      it { expect { subject }.to raise_error(error) }
    end
  end

  describe '.update_or_create_with_token!' do
    let(:values) do
      {
          uid: 123,
          screen_name: 'sn',
          secret: 's',
          token: 't',
          email: 'a@a.com',
      }
    end
    subject { described_class.update_or_create_with_token!(values) }

    context 'user is persisted' do
      before { allow(described_class).to receive(:exists?).with(uid: 123).and_return(true) }
      it do
        expect(described_class).to receive(:update_with_token).with(123, 'sn', 'a@a.com', 't', 's')
        subject
      end
    end

    context 'user is NOT persisted' do
      it do
        expect(described_class).to receive(:create_with_token).with(123, 'sn', 'a@a.com', 't', 's')
        subject
      end
    end
  end

  describe '.create_with_token' do
    subject { described_class.create_with_token(123, 'screen_name', 'a@b.com', 'token', 'secret') }
    it do
      user = subject
      expect(user.uid).to eq(123)
      expect(user.screen_name).to eq('screen_name')
      expect(user.email).to eq('a@b.com')
      expect(user.token).to eq('token') if user.respond_to?(:token)
      expect(user.secret).to eq('secret') if user.respond_to?(:secret)
      expect(user.credential_token.token).to eq('token')
      expect(user.credential_token.secret).to eq('secret')
      expect(user.notification_setting.permission_level).to eq('read-write-directmessages')
    end
  end

  describe '.update_with_token' do
    let(:persisted_user) { create(:user, with_credential_token: true) }
    let(:screen_name) { 'screen_name' }
    let(:email) { 'a@b.com' }
    subject { described_class.update_with_token(persisted_user.uid, screen_name, email, 'token', 'secret') }
    it do
      user = subject
      expect(user.uid).to eq(persisted_user.uid)
      expect(user.screen_name).to eq(screen_name)
      expect(user.email).to eq(email)
      expect(user.token).to eq('token') if user.respond_to?(:token)
      expect(user.secret).to eq('secret') if user.respond_to?(:secret)
      expect(user.credential_token.token).to eq('token')
      expect(user.credential_token.secret).to eq('secret')
    end

    context 'screen_name is nil' do
      let(:screen_name) { nil }
      it { expect(subject.screen_name).not_to be_nil }
    end

    context 'email is nil' do
      let(:email) { nil }
      it { expect(subject.email).not_to be_nil }
    end
  end

  describe '.api_client' do
    let(:user) { create(:user, with_credential_token: true) }
    it 'returns ApiClient' do
      client = user.api_client
      expect(client).to be_a_kind_of(ApiClient)
      expect(client.access_token).to eq(user.token)
      expect(client.access_token_secret).to eq(user.secret)
    end
  end

  describe '#is_following?' do
    let(:user) { create(:user) }

    before do
      allow(user).to receive(:current_friend_uids).with(no_args).and_return([1, 2])
    end

    it do
      expect(user.is_following?(1)).to be_truthy
      expect(user.is_following?(2)).to be_truthy
      expect(user.is_following?(3)).to be_falsey
    end
  end

  describe '#current_friend_uids' do
    let(:user) { create(:user) }
    let(:time) { Time.zone.now }
    let(:twitter_user) { Hashie::Mash.new(friend_uids: [1, 2, 3], created_at: 1.year.ago) }
    let(:following_request1) { FollowRequest.new(uid: 4, created_at: time + 1.second) }
    let(:unfollowing_request1) { UnfollowRequest.new(uid: 2, created_at: time + 2.seconds) }
    let(:following_request2) { FollowRequest.new(uid: 5, created_at: time + 3.seconds) }
    let(:unfollowing_request2) { UnfollowRequest.new(uid: 4, created_at: time + 4.seconds) }

    context 'There are no requests' do
      before do
        allow(TwitterUser).to receive(:latest_by).with(uid: user.uid).and_return(twitter_user)
        allow(user).to receive(:following_requests).with(twitter_user.created_at).and_return([])
        allow(user).to receive(:unfollowing_requests).with(twitter_user.created_at).and_return([])
      end

      it { expect(user.current_friend_uids).to match_array([1, 2, 3]) }
    end

    context 'There are 2 following requests and 2 unfollowing requests' do
      before do
        allow(TwitterUser).to receive(:latest_by).with(uid: user.uid).and_return(twitter_user)
        allow(user).to receive(:following_requests).with(twitter_user.created_at).and_return([following_request1, following_request2])
        allow(user).to receive(:unfollowing_requests).with(twitter_user.created_at).and_return([unfollowing_request1, unfollowing_request2])
      end

      it { expect(user.current_friend_uids).to match_array([1, 3, 5]) }
    end

    context 'Without twitter_user' do
      context 'There are 2 following requests and 2 unfollowing requests' do
        before do
          allow(TwitterUser).to receive(:latest_by).with(uid: user.uid).and_return(nil)
          allow(user).to receive(:following_requests).with(nil).and_return([following_request1, following_request2])
          allow(user).to receive(:unfollowing_requests).with(nil).and_return([unfollowing_request1, unfollowing_request2])
        end

        it { expect(user.current_friend_uids).to match_array([5]) }
      end
    end
  end

  describe 'Scope premium' do
    let!(:user) { create(:user, with_orders: true) }
    before do
      user2 = create(:user, with_orders: true)
      user2.orders.last.update!(canceled_at: Time.zone.now)

      create(:user)
    end

    it { expect(User.premium.pluck(:id)).to eq([user.id]) }
  end

  describe '#sharing_count' do
    subject { user.sharing_count }
    before do
      user.save!
      user.tweet_requests.create!(tweet_id: 1, text: 'text', deleted_at: nil)
      user.tweet_requests.create!(tweet_id: 2, text: 'text', deleted_at: nil)
      user.tweet_requests.create!(tweet_id: nil, text: 'text', deleted_at: nil)
      user.tweet_requests.create!(tweet_id: 3, text: 'text', deleted_at: Time.zone.now)
      user.tweet_requests.create!(tweet_id: nil, text: 'text', deleted_at: Time.zone.now)
    end
    it { is_expected.to eq(2) }
  end

  describe '#add_atmark_to_periodic_report?' do
    subject { user.add_atmark_to_periodic_report? }
    before { user.save! }

    context 'user is created now' do
      it { is_expected.to be_truthy }
    end

    context 'user is created a long time ago' do
      before { user.update!(created_at: 1.month.ago) }
      it { is_expected.to be_falsey }
    end
  end

  describe '#continuous_sign_in?' do
    let(:user) { create(:user, with_access_days: 1) }
    subject { user.continuous_sign_in? }
    it { is_expected.to be_truthy }
  end
end
