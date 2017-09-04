require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build(:user) }

  context 'validation' do
    it 'passes all' do
      expect(User.new.tap { |u| u.valid? }.errors[:uid].size).to eq(2)
      expect(User.new(uid: -1).tap { |u| u.valid? }.errors[:uid].size).to eq(1)
      expect(User.new(uid: 1).tap { |u| u.valid? }.errors[:uid].size).to eq(0)

      expect(User.new.tap { |u| u.valid? }.errors[:screen_name].size).to eq(2)
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

  describe '.update_or_create_for_oauth_by!' do
    let(:auth) do
      Hashie::Mash.new(
        uid: 1,
        info: {nickname: 'sn', email: 'info@egotter.com'},
        credentials: {secret: 's', token: 't'},
      )
    end

    it 'saves new user' do
      result = nil
      expect { result = User.update_or_create_for_oauth_by!(auth) }.to change { User.all.size }.by(1)
      expect(result.uid.to_i).to eq(auth.uid)
      expect(result.screen_name).to eq(auth.info.nickname)
      expect(result.email).to eq(auth.info.email)
      expect(result.secret).to eq(auth.credentials.secret)
      expect(result.token).to eq(auth.credentials.token)
    end

    context 'without uid' do
      it 'raises an ActiveRecord::RecordInvalid' do
        auth.delete(:uid)
        expect { User.update_or_create_for_oauth_by!(auth) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'without info.nickname' do
      it 'raises an ActiveRecord::RecordInvalid' do
        auth.info.delete(:nickname)
        expect { User.update_or_create_for_oauth_by!(auth) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'without info.email' do
      it 'does not raise any exception' do
        auth.info.delete(:email)
        expect { User.update_or_create_for_oauth_by!(auth) }.to_not raise_error
      end
    end

    context 'without credentials.secret' do
      it 'raises an ActiveRecord::RecordInvalid' do
        auth.credentials.delete(:secret)
        expect { User.update_or_create_for_oauth_by!(auth) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'without credentials.token' do
      it 'raises an ActiveRecord::RecordInvalid' do
        auth.credentials.delete(:token)
        expect { User.update_or_create_for_oauth_by!(auth) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '.api_client' do
    it 'returns TwitterWithAutoPagination::Client' do
      client = user.api_client
      expect(client).to be_a_kind_of(TwitterWithAutoPagination::Client)
      expect(client.access_token).to eq(user.token)
      expect(client.access_token_secret).to eq(user.secret)
    end
  end

  describe '#setup_stripe' do
    let(:stripe_helper) { StripeMock.create_test_helper }
    let(:email) { 'a@aaa.com' }
    let(:source) { stripe_helper.generate_card_token }

    before do
      user.save!
      StripeMock.start
    end
    after { StripeMock.stop }

    it 'creates Stripe::Customer' do
      user.setup_stripe(email, source, metadata: {})
      expect(user.customer).to be_truthy
      expect(Stripe::Customer.retrieve(user.customer.customer_id).email).to eq(email)
    end

    context 'continuous calls' do
      before { user.setup_stripe(email, source, metadata: {}) }

      it 'does nothing' do
        expect(Stripe::Customer).to_not receive(:create)
        expect(user).to_not receive(:create_customer!)
        user.setup_stripe(email, source, metadata: {})
      end
    end
  end
end
