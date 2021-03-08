require 'rails_helper'

RSpec.describe CreateEgotterBlockerWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(1) }
    it { expect { subject }.to change { EgotterBlocker.all.size }.by(1) }
  end
end
