require 'rails_helper'

RSpec.describe SortedSetCleanupWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(class_str) }
    [
        GlobalDirectMessageReceivedFlag,
        GlobalDirectMessageSentFlag
    ].each do |klass|
      context "#{klass} is passed" do
        let(:class_str) { klass.to_s }
        it do
          expect(klass).to receive_message_chain(:new, :cleanup)
          subject
        end
      end
    end
  end
end
