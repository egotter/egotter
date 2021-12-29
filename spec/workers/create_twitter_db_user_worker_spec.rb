require 'rails_helper'

RSpec.describe CreateTwitterDBUserWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  before do
    allow(User).to receive(:find_by).with(id: user.id).and_return(user)
  end

  describe '.perform_async' do
    let(:worker_wrapper) do
      Class.new(described_class) do
        def perform(uids, options)
          self.class.do_perform(uids, options)
        end

        class << self
          def do_perform(*) end
        end
      end
    end

    context '100 < uids.size' do
      let(:uids1) { (1..100).to_a }
      let(:encoded_uids1) { Base64.encode64(Zlib::Deflate.deflate(uids1.join(','))) }
      let(:uids2) { (101..110).to_a }
      let(:uids) { (1..110).to_a }
      it do
        expect(worker_wrapper).to receive(:do_perform).with(encoded_uids1, {})
        expect(worker_wrapper).to receive(:do_perform).with(uids2, {})
        worker_wrapper.perform_async(uids)
        worker_wrapper.drain
      end
    end

    context '10 < uids.size < 100' do
      let(:uids) { (1..50).to_a }
      let(:encoded_uids) { Base64.encode64(Zlib::Deflate.deflate(uids.join(','))) }
      it do
        expect(worker_wrapper).to receive(:do_perform).with(encoded_uids, {})
        worker_wrapper.perform_async(uids)
        worker_wrapper.drain
      end
    end

    context 'uids.size < 10' do
      let(:uids) { (1..5).to_a }
      it do
        expect(worker_wrapper).to receive(:do_perform).with(uids, {})
        worker_wrapper.perform_async(uids)
        worker_wrapper.drain
      end
    end
  end

  describe '#perform' do
    let(:uids) { [1] }
    let(:options) { {'user_id' => user.id} }
    let(:client) { 'client' }
    let(:task) { double('task') }
    subject { worker.perform(uids, options) }

    before do
      allow(user).to receive(:api_client).and_return(client)
    end

    it do
      expect(CreateTwitterDBUsersTask).to receive(:new).with(uids, user_id: user.id, force: nil).and_return(task)
      expect(task).to receive(:start)
      expect(task).to receive(:debug_message)
      subject
    end
  end
end
