require 'rails_helper'

RSpec.describe Decorator do
  let(:users) { [build(:user), build(:user)] }
  let(:client) { double('Client') }
  let(:instance) { described_class.new(users) }

  before do
    allow(instance).to receive(:client).and_return(client)
  end

  describe '#suspended_uids' do
    let(:api_users) { [{id: users[0].uid}, {id: users[1].uid}] }
    subject { instance.send(:suspended_uids) }
    before do
      allow(client).to receive(:users).with(users.map(&:uid)).and_return(api_users)
    end
    it { is_expected.to be_empty }

    context 'the client is unauthorized' do
      let(:error) { RuntimeError.new('error') }
      before do
        allow(client).to receive(:users).with(anything).and_raise(error)
        allow(AccountStatus).to receive(:unauthorized?).with(error).and_return(true)
      end
      it { is_expected.to be_empty }
    end
  end

  describe '#blocking_uids' do
    subject { instance.send(:blocking_uids) }
    context 'the client is unauthorized' do
      let(:error) { RuntimeError.new('error') }
      before do
        allow(client).to receive(:users).with(anything).and_raise(error)
        allow(AccountStatus).to receive(:unauthorized?).with(error).and_return(true)
      end
      it { is_expected.to be_empty }
    end
  end
end
