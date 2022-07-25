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
    let(:data) { double('data') }
    let(:uids) { [1, 2, 3] }
    let(:options) { {} }
    subject { worker.perform(data, options) }

    before do
      allow(worker).to receive(:decompress).with(data).and_return(uids)
    end

    it do
      expect(worker).to receive(:do_perform).with(uids, options)
      subject
    end

    context 'ApiClient::RetryExhausted is raised' do
      let(:error) { ApiClient::RetryExhausted.new }
      before { allow(worker).to receive(:do_perform).with(uids, options).and_raise(error) }
      it do
        expect(CreateTwitterDBUserForRetryableErrorWorker).to receive(:perform_in).
            with(instance_of(Integer), data, anything)
        subject
      end
    end

    context 'RuntimeError is raised' do
      let(:error) { RuntimeError.new }
      before { allow(worker).to receive(:do_perform).with(uids, options).and_raise(error) }
      it do
        expect(FailedCreateTwitterDBUserWorker).to receive(:perform_async).with(data, anything)
        subject
      end
    end
  end

  describe '#do_perform' do
    let(:worker) { described_class.new }
    let(:uids) { [1, 2, 3] }
    let(:user_id) { 1 }
    let(:options) { {'user_id' => user_id, 'enqueued_by' => 'test'} }
    subject { worker.send(:do_perform, uids, options) }
    it do
      expect(worker).to receive(:extract_user_id).with(options).and_return(user_id)
      expect(CreateTwitterDBUsersTask).to receive_message_chain(:new, :start).
          with(uids, user_id: user_id, enqueued_by: 'test').with(no_args)
      subject
    end
  end
end
