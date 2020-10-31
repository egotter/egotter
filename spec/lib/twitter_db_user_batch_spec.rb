require 'rails_helper'

RSpec.describe TwitterDBUserBatch, type: :model do
  let(:client) { double('client') }
  let(:instance) { described_class.new(client) }

  describe '#import!' do
    let(:uids) { [1, 2, 2, 3] }
    let(:users) { [{id: 1}, {id: 2}, {id: 3}] }
    subject { instance.import!(uids) }

    it do
      expect(instance).to receive(:fetch_users).with([1, 2, 3]).and_return(users)
      expect(instance).to receive(:import_users).with(users, false).and_return(users)
      expect(instance).not_to receive(:import_suspended_users)
      subject
    end
  end

  describe '#fetch_users' do
    let(:uids) { [1, 2, 2, 3] }
    let(:users) { [{id: 1}, {id: 2}, {id: 3}] }
    subject { instance.send(:fetch_users, uids) }

    it do
      expect(client).to receive_message_chain(:twitter, :users).with(uids).and_return(users)
      subject
    end
  end

  describe '#import_users' do
    let(:users) { [{id: 1}, {id: 2}, {id: 3}] }
    subject { instance.send(:import_users, users, false) }

    it do
      expect(TwitterDB::User).to receive(:import_by!).with(users: users)
      subject
    end
  end

  describe '#import_suspended_users' do
    let(:uids) { [1, 2, 2, 3] }
    subject { instance.send(:import_suspended_users, uids) }

    it { is_expected.to eq([1, 2, 3]) }
  end
end

