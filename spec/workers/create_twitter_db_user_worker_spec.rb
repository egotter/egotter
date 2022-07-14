require 'rails_helper'

RSpec.describe CreateTwitterDBUserWorker do
  let(:user) { create(:user) }

  before { allow(User).to receive(:find_by).with(id: user.id).and_return(user) }

  describe '.perform_async' do
    class TestCreateTwitterDBUserWorker < CreateTwitterDBUserWorker
      def perform(uids, options)
        self.class.do_perform(uids, options)
      end

      class << self
        def do_perform(*) end
      end
    end

    let(:worker) do
      TestCreateTwitterDBUserWorker
    end

    before { Redis.new.flushall }

    subject do
      worker.perform_async(uids)
      worker.drain
    end

    context 'uids.size < 100' do
      let(:uids1) { (1..50).to_a }
      let(:encoded_uids1) { 'encoded_uids1' }
      let(:uids) { (1..50).to_a }
      before { allow(worker).to receive(:compress).with(uids1).and_return(encoded_uids1) }
      it do
        expect(worker).to receive(:do_perform).with(encoded_uids1, {})
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
        allow(worker).to receive(:compress).with(uids1).and_return(encoded_uids1)
        allow(worker).to receive(:compress).with(uids2).and_return(encoded_uids2)
      end
      it do
        expect(worker).to receive(:do_perform).with(encoded_uids1, {})
        expect(worker).to receive(:do_perform).with(encoded_uids2, {})
        subject
      end
    end
  end

  describe '#perform' do
    let(:worker) { described_class.new }
    let(:uids) { [1] }
    let(:options) { {'user_id' => user.id, 'enqueued_by' => 'test'} }
    let(:client) { 'client' }
    let(:task) { double('task') }
    subject { worker.perform(uids, options) }

    before do
      allow(user).to receive(:api_client).and_return(client)
    end

    it do
      expect(CreateTwitterDBUsersTask).to receive(:new).with(uids, user_id: user.id, force: nil, enqueued_by: 'test').and_return(task)
      expect(task).to receive(:start)
      subject
    end

    context 'error is raised' do
      let(:error) { RuntimeError.new }
      before do
        allow(CreateTwitterDBUsersTask).to receive(:new).with(any_args).and_raise(error)
      end
      it do
        expect(FailedCreateTwitterDBUserWorker).to receive(:perform_async).with(uids, anything)
        subject
      end
    end
  end
end
