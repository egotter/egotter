require 'rails_helper'

RSpec.describe CreateTwitterDBUsersTask, type: :model do
  let(:uids) { [1, 2, 3, 4, 5] }
  let(:users) { uids.map { |id| {id: id, screen_name: "sn-#{id}"} } }
  let(:twitter) { double('twitter') }
  let(:client) { double('client', twitter: twitter) }
  let(:instance) { described_class.new(uids, enqueued_by: 'test') }

  before do
    allow(Bot).to receive(:api_client).and_return(client)
  end

  describe '#start' do
    subject { instance.start }

    it do
      expect(instance).to receive(:reject_fresh_uids).with(uids).and_return(uids)
      expect(instance).to receive(:fetch_users).with(client, uids).and_return(users)
      expect(ImportTwitterDBUserWorker).to receive(:perform_async).with(users, enqueued_by: 'test', _user_id: nil)
      subject
    end

    context 'suspended uids found' do
      let(:users) { uids.slice(0, 2).map { |id| {id: id, screen_name: "sn-#{id}"} } }
      it do
        expect(instance).to receive(:fetch_users).with(client, uids).and_return(users)
        expect(ImportTwitterDBUserWorker).to receive(:perform_async).with(users, enqueued_by: 'test', _user_id: nil)
        subject
      end
    end
  end

  describe '#fetch_users' do
    subject { instance.send(:fetch_users, client, uids) }
    it do
      expect(twitter).to receive(:users).with(uids).and_return(users)
      subject
    end
  end

  describe '#reject_fresh_uids' do
    subject { instance.send(:reject_fresh_uids, uids) }
    it { is_expected.to eq(uids) }

    context 'a user is already persisted' do
      before { create(:twitter_db_queued_user, uid: uids[0]) }
      it { is_expected.to eq(uids[1..-1]) }
    end
  end
end
