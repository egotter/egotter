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

      %i(secret token).each do |attr|
        expect(User.new.tap { |u| u.valid? }.errors[attr].size).to eq(1)
      end
      %i(secret token).product([nil, '']).each do |attr, value|
        expect(User.new(attr => value).tap { |u| u.valid? }.errors[attr].size).to eq(1)
      end

      expect(User.new.tap { |u| u.valid? }.errors[:email].size).to eq(0)
      expect(User.new(email: nil).tap { |u| u.valid? }.errors[:email].size).to eq(1)
      expect(User.new(email: '').tap { |u| u.valid? }.errors[:email].size).to eq(0)
      expect(User.new(email: 'info@egotter.com').tap { |u| u.valid? }.errors[:email].size).to eq(0)
    end
  end

  describe '.update_or_create_with_token!' do
    let(:values) do
      {
          uid: 123,
          screen_name: 'sn',
          secret: 's',
          token: 't',
          authorized: true,
          email: 'a@a.com',
      }.compact
    end
    subject { User.update_or_create_with_token!(values) }

    context 'With new uid' do
      it 'creates new user' do
        expect { subject }.to change { User.all.size }.by(1)

        user = User.last
        expect(user.slice(values.keys)).to match(values)
      end
    end

    context 'With persisted uid' do
      before { create(:user, uid: values[:uid]) }
      it 'updates the user' do
        expect { subject }.to_not change { User.all.size }

        user = User.last
        expect(user.slice(values.keys)).to match(values)
      end
    end

    context 'without uid' do
      before { values.delete(:uid) }
      it 'raises an ActiveRecord::RecordInvalid' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'without screen_name' do
      before { values.delete(:screen_name) }
      it 'raises an ActiveRecord::RecordInvalid' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'without email' do
      before { values.delete(:email) }
      it 'does not raise any exception' do
        expect { subject }.to_not raise_error
      end
    end

    context 'without secret' do
      before { values.delete(:secret) }
      it 'raises an ActiveRecord::RecordInvalid' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'without token' do
      before { values.delete(:token) }
      it 'raises an ActiveRecord::RecordInvalid' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '.find_by_token' do
    subject { User.find_by_token('t', 's') }
    it do
      expect(User).to receive(:find_by).with(token: 't', secret: 's')
      subject
    end
  end

  describe '.authorized_ids' do
    subject { User.authorized_ids }
    before do
      Redis.client.flushdb
      user.save!
    end
    it { is_expected.to eq([user.id]) }
  end

  describe '.pick_authorized_id' do
    subject { User.pick_authorized_id }
    before do
      user.save!
      allow(User).to receive(:authorized_ids).and_return([user.id])
      allow(User).to receive(:find).with(user.id).and_return(user)
      allow(user).to receive_message_chain(:api_client, :twitter, :verify_credentials)
      allow(user).to receive_message_chain(:api_client, :twitter, :users).with(no_args).with([user.uid, user.id])
    end
    it { is_expected.to eq(user.id) }
  end

  describe '.api_client' do
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
      user.tweet_requests.create!(tweet_id: 123, text: 'text')
    end
    it { is_expected.to eq(1) }
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
end
