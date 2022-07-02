require 'rails_helper'

RSpec.describe ImportTwitterDBUserWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:users) { [{'id' => 1, 'screen_name' => 'name1'}, {'id' => 2, 'screen_name' => 'name2'}] }
    subject { worker.perform(users) }

    it do
      expect(worker).to receive(:import_users).with(users)
      subject
    end

    context 'encoded users are passed' do
      let(:encoded_users) { Base64.encode64(Zlib::Deflate.deflate(users.to_json)) }
      subject { worker.perform(encoded_users) }
      it do
        expect(worker).to receive(:import_users).with(users)
        subject
      end
    end

    context 'deadlock error is raised' do
      let(:error) { described_class::Deadlocked }
      before do
        allow(worker).to receive(:import_users).with(users).and_raise(error)
      end
      it do
        expect(ImportTwitterDBUserForRetryingDeadlockWorker).to receive(:perform_in).with(instance_of(Integer), users, anything)
        subject
      end
    end

    context 'error is raised' do
      let(:error) { RuntimeError.new }
      before do
        allow(worker).to receive(:import_users).with(users).and_raise(error)
      end
      it do
        expect(FailedImportTwitterDBUserWorker).to receive(:perform_async).with(users, anything)
        subject
      end
    end
  end
end
