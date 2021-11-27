require 'rails_helper'

RSpec.describe CreateTwitterDBUserWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  before do
    allow(User).to receive(:find_by).with(id: user.id).and_return(user)
  end

  describe '.compress_and_perform_async' do
    let(:options) { {} }
    subject { described_class.compress_and_perform_async(uids, options) }

    context 'uids.size is 50' do
      let(:uids) { (1..50).to_a }
      let(:compressed_uids) { described_class.compress((1..50).to_a) }
      let(:new_options) { {compressed: true} }
      it do
        expect(described_class).to receive(:perform_async).with(compressed_uids, new_options)
        subject
      end
    end

    context 'uids.size is 150' do
      let(:uids) { (1..150).to_a }
      let(:compressed_uids1) { described_class.compress((1..100).to_a) }
      let(:compressed_uids2) { described_class.compress((101..150).to_a) }
      let(:new_options) { {compressed: true} }
      it do
        expect(described_class).to receive(:perform_async).with(compressed_uids1, new_options)
        expect(described_class).to receive(:perform_async).with(compressed_uids2, new_options)
        subject
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
