require 'rails_helper'

RSpec.describe CreateTwitterDBUserWorker do
  let(:user) { create(:user) }

  before { allow(User).to receive(:find_by).with(id: user.id).and_return(user) }

  describe '.push_bulk' do
    before { Redis.new.flushall }
    subject { described_class.push_bulk(uids) }

    context 'uids.size < 100' do
      let(:uids1) { (1..50).to_a }
      let(:encoded_uids1) { 'encoded_uids1' }
      let(:uids) { (1..50).to_a }
      before { allow(described_class).to receive(:compress).with(uids1).and_return(encoded_uids1) }
      it do
        expect(described_class).to receive(:perform_in).with(instance_of(Integer), encoded_uids1, {})
        subject
      end
    end

    context '100 < uids.size' do
      let(:uids1) { (1..100).to_a }
      let(:encoded_uids1) { 'encoded_uids1' }
      let(:uids2) { (101..110).to_a }
      let(:encoded_uids2) { 'encoded_uids2' }
      let(:uids) { (1..110).to_a }
      before do
        allow(described_class).to receive(:compress).with(uids1).and_return(encoded_uids1)
        allow(described_class).to receive(:compress).with(uids2).and_return(encoded_uids2)
      end
      it do
        expect(described_class).to receive(:perform_in).with(instance_of(Integer), encoded_uids1, {})
        expect(described_class).to receive(:perform_in).with(instance_of(Integer), encoded_uids2, {})
        subject
      end
    end
  end

  describe '#perform' do
    let(:worker) { described_class.new }
    let(:data) { double('data') }
    let(:uids) { [1, 2, 3] }
    let(:user_id) { 1 }
    let(:options) { {'user_id' => user_id, 'enqueued_by' => 'test'} }
    subject { worker.perform(data, options) }

    before do
      allow(worker).to receive(:decompress).with(data).and_return(uids)
    end

    it do
      expect(worker).to receive(:do_perform).with(uids, user_id, options)
      subject
    end

    context 'ApiClient::RetryExhausted is raised' do
      let(:error) { ApiClient::RetryExhausted.new }
      before { allow(worker).to receive(:do_perform).with(uids, user_id, options).and_raise(error) }
      it do
        expect(CreateTwitterDBUserForRetryableErrorWorker).to receive(:perform_in).
            with(instance_of(Integer), data, anything)
        subject
      end
    end

    context 'RuntimeError is raised' do
      let(:error) { RuntimeError.new }
      before { allow(worker).to receive(:do_perform).with(uids, user_id, options).and_raise(error) }
      it do
        expect(FailedCreateTwitterDBUserWorker).to receive(:perform_async).with(data, anything)
        subject
      end
    end
  end

  describe '#do_perform' do
    let(:worker) { described_class.new }
    let(:uids) { [1, 2, 3, 4, 5] }
    let(:users) { [{id: 1}, {id: 3}, {id: 5}] }
    let(:user_id) { 1 }
    let(:client) { double('client') }
    let(:options) { {'user_id' => user_id, 'enqueued_by' => 'test'} }
    subject { worker.send(:do_perform, uids, user_id, options) }
    before do
      create(:twitter_db_queued_user, uid: 2)
      allow(worker).to receive(:client).with(user_id).and_return(client)
    end
    it do
      expect(TwitterDB::QueuedUser).to receive(:mark_uids_as_processing).with([1, 3, 4, 5])
      expect(client).to receive(:safe_users).with([1, 3, 4, 5]).and_return(users)
      expect(ImportTwitterDBSuspendedUserWorker).to receive(:perform_async).with([4])
      expect(ImportTwitterDBUserWorker).to receive(:perform_in).
          with(instance_of(Integer), users, enqueued_by: 'test', _user_id: user_id, _size: users.size)
      subject
    end
  end
end
