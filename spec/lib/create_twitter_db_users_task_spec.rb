require 'rails_helper'

RSpec.describe CreateTwitterDBUsersTask, type: :model do
  let(:instance) { described_class.new(uids, enqueued_by: 'test') }

  describe '#start' do
    let(:uids) { [1, 2, 3] }
    let(:users) { uids.map { |id| {id: id, screen_name: "sn-#{id}"} } }
    subject { instance.start }

    it do
      expect(instance).to receive(:fetch_users).with(uids).and_return(users)
      expect(ImportTwitterDBUserWorker).to receive(:perform_async).with(users, enqueued_by: 'test', _user_id: nil, _size: 3)
      subject
    end

    context 'suspended uids found' do
      let(:users) { [{id: 1, screen_name: 'sn1'}, {id: 2, screen_name: 'sn2'}] }
      it do
        expect(instance).to receive(:fetch_users).with(uids).and_return(users)
        expect(ImportTwitterDBSuspendedUserWorker).to receive(:perform_async).with([3])
        subject
      end
    end
  end

  describe '#fetch_users' do
    let(:client) { double('client') }
    let(:uids) { [1, 2, 3] }
    let(:users) { uids.map { |id| {id: id, screen_name: "sn-#{id}"} } }
    subject { instance.send(:fetch_users, uids) }
    before { instance.instance_variable_set(:@client, client) }
    it do
      expect(client).to receive(:users).with(uids).and_return(users)
      subject
    end
  end

  describe '#client' do
    subject { described_class.new([], user_id: 1).send(:client) }
    before { allow(RateLimitExceededFlag).to receive(:on?).with(1).and_return(false) }
    it do
      expect(User).to receive_message_chain(:find, :api_client, :twitter).
          with(1).with(no_args).with(no_args)
      subject
    end

    context 'user_id is not passed' do
      subject { described_class.new([]).send(:client) }
      it do
        expect(Bot).to receive_message_chain(:api_client, :twitter).
            with(no_args).with(no_args)
        subject
      end
    end
  end
end
