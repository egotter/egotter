require 'rails_helper'

RSpec.describe SearchRequestValidator, type: :model do
  let(:instance) { described_class.new(user) }

  shared_context 'user is signed in' do
    let(:user) { build(:user) }
  end

  shared_context 'user is not signed in' do
    let(:user) { nil }
  end

  describe '#user_requested_self_search?' do
    let(:screen_name) { user&.screen_name }
    subject { instance.user_requested_self_search?(screen_name) }

    context 'user is signed in' do
      include_context 'user is signed in'

      context 'signed-in user is searching himself' do
        before do
          allow(instance).to receive_message_chain(:client, :user).
              with(no_args).with(screen_name).and_return(id: user.uid)
        end
        it { is_expected.to be_truthy }
      end

      context 'signed-in user is not searching himself' do
        before do
          allow(instance).to receive_message_chain(:client, :user).
              with(no_args).with(screen_name).and_return(id: nil)
        end
        it { is_expected.to be_falsey }
      end
    end

    context 'user is not signed in' do
      include_context 'user is not signed in'
      it { is_expected.to be_falsey }
    end
  end
end
