require 'rails_helper'

RSpec.describe SearchRequestValidator, type: :model do
  let(:instance) { described_class.new(client, user) }
  let(:user) { nil }
  let(:client) { double('client') }

  shared_context 'user is signed in' do
    let(:user) { build(:user) }
  end

  shared_context 'user is not signed in' do
    let(:user) { nil }
  end

  describe '#search_for_yourself?' do
    let(:screen_name) { user&.screen_name }
    subject { instance.search_for_yourself?(screen_name) }

    context 'user is signed in' do
      include_context 'user is signed in'
      before { allow(client).to receive(:user).with(screen_name).and_return(api_user) }

      context 'signed-in user is searching for himself' do
        let(:api_user) { {id: user.uid} }
        it { is_expected.to be_truthy }
      end

      context 'signed-in user is not searching for himself' do
        let(:api_user) { {id: user.uid + 1} }
        it { is_expected.to be_falsey }
      end
    end

    context 'user is not signed in' do
      include_context 'user is not signed in'
      it { is_expected.to be_falsey }
    end
  end

  describe '#user_requested_self_search_by_uid?' do
    subject { instance.user_requested_self_search_by_uid?(uid) }

    context 'user is signed in' do
      include_context 'user is signed in'

      context 'signed-in user is searching for himself' do
        # This value is passed from params, so it's String
        let(:uid) { user.uid.to_s }
        it { is_expected.to be_truthy }
      end

      context 'signed-in user is not searching for himself' do
        let(:uid) { (user.uid + 1).to_s }
        it { is_expected.to be_falsey }
      end
    end

    context 'user is not signed in' do
      include_context 'user is not signed in'
      let(:uid) { 1 }
      it { is_expected.to be_falsey }
    end
  end

  describe 'blocked_user?' do
    let(:screen_name) { 'name' }
    subject { instance.blocked_user?(screen_name) }
    before { allow(instance).to receive(:user_signed_in?).and_return(true) }
    it do
      expect(client).to receive(:user_timeline).with(screen_name, count: 1)
      is_expected.to be_falsey
    end

    context 'exception is raised' do
      let(:error) { RuntimeError.new }
      before { allow(client).to receive(:user_timeline).with(any_args).and_raise(error) }
      it do
        expect(TwitterApiStatus).to receive(:blocked?).with(error)
        is_expected.to be_falsey
      end
    end
  end

  describe '#protected_user?' do
    let(:screen_name) { 'name' }
    let(:response_user) { {protected: false} }
    subject { instance.protected_user?(screen_name) }
    it do
      expect(client).to receive(:user).with(screen_name).and_return(response_user)
      is_expected.to be_falsey
    end

    context 'exception is raised' do
      let(:error) { RuntimeError.new }
      before { allow(client).to receive(:user).with(anything).and_raise(error) }
      it do
        expect(TwitterApiStatus).to receive(:protected?).with(error)
        is_expected.to be_falsey
      end
    end
  end

  describe '#timeline_readable?' do
    include_context 'user is not signed in'
    subject { instance.timeline_readable?('name') }
    before { allow(client).to receive(:user_timeline).with('name', count: 1).and_return('result') }
    it { is_expected.to be_truthy }
  end
end
