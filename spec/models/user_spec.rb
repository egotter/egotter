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
end
