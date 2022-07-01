require 'rails_helper'

RSpec.describe CreateAirbagLogWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform('INFO', 'message', nil, Time.zone.now) }
    it { expect { subject }.to change { AirbagLog.all.size }.by(1) }
  end
end
