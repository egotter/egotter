require 'rails_helper'

RSpec.describe CreateDirectMessageErrorLogWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform([1, 'message'], 'error_class', 'error_message', Time.zone.now) }
    it { expect { subject }.to change { DirectMessageErrorLog.all.size }.by(1) }
  end
end
