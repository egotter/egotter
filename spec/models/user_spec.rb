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
        expect { subject }.to change {User.all.size}.by(1)

        user = User.last
        expect(user.slice(values.keys)).to match(values)
      end
    end

    context 'With persisted uid' do
      before { create(:user, uid: values[:uid]) }
      it 'updates the user' do
        expect { subject }.to_not change {User.all.size}

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

  describe '.api_client' do
    it 'returns ApiClient' do
      client = user.api_client
      expect(client).to be_a_kind_of(ApiClient)
      expect(client.access_token).to eq(user.token)
      expect(client.access_token_secret).to eq(user.secret)
    end
  end

  describe '#active_access?' do
    let(:user) { create(:user) }

    context 'last access is within the last 3 days' do
      let(:days_count) { 3 }
      before { user.update!(last_access_at: (days_count - 1).days.ago) }
      it { expect(user.active_access?(days_count)).to be_truthy }
    end

    context 'last access is more than the last 3 days' do
      let(:days_count) { 3 }
      before { user.update!(last_access_at: (days_count + 1).days.ago) }
      it { expect(user.active_access?(days_count)).to be_falsey}
    end
  end

  describe '#inactive_access?' do
    let(:user) { create(:user) }

    context 'last access is within the last 3 days' do
      let(:days_count) { 3 }
      before { user.update!(last_access_at: (days_count - 1).days.ago) }
      it { expect(user.inactive_access?(days_count)).to be_falsey }
    end

    context 'last access is more than the last 3 days' do
      let(:days_count) { 3 }
      before { user.update!(last_access_at: (days_count + 1).days.ago) }
      it { expect(user.inactive_access?(days_count)).to be_truthy}
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

  describe 'Scope enough_permission_level' do
    subject { User.enough_permission_level }
    before do
      user.save!
      user.create_notification_setting!(permission_level: level)
    end

    context 'Enough permission_level' do
      let(:level) { 'read-write-directmessages' }
      it { is_expected.to match_array([user]) }
    end

    context 'Not enough permission_level' do
      let(:level) { 'read-write' }
      it { is_expected.to be_empty }
    end
  end

  describe 'Scope prompt_report_enabled' do
    subject { User.prompt_report_enabled }
    before do
      user.save!
      user.create_notification_setting!(dm: dm_value)
    end

    context 'notification_settings.dm == true' do
      let(:dm_value) { true }
      it { is_expected.to match_array([user]) }
    end

    context 'notification_settings.dm == false' do
      let(:dm_value) { false }
      it { is_expected.to be_empty }
    end
  end

  describe 'Scope prompt_report_interval_ok' do
    subject { User.prompt_report_interval_ok }
    let(:report_interval) { NotificationSetting::DEFAULT_REPORT_INTERVAL }
    before do
      user.save!
      user.create_notification_setting!(last_dm_at: last_dm_at, report_interval: report_interval)
    end

    context 'notification_settings.last_dm_at == nil' do
      let(:last_dm_at) { nil }
      it { is_expected.to match_array([user]) }
    end

    context 'notification_settings.last_dm_at is less than report_interval' do
      let(:last_dm_at) { report_interval.seconds.ago - 1 }
      it { is_expected.to match_array([user]) }
    end

    context 'notification_settings.last_dm_at is more than report_interval' do
      let(:last_dm_at) { report_interval.seconds.ago + 1 }
      it { is_expected.to be_empty }
    end
  end
end
