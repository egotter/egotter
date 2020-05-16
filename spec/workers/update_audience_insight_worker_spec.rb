require 'rails_helper'

RSpec.describe UpdateAudienceInsightWorker do
  describe '#retry_in' do
    let(:worker) { described_class.new }
    it { expect(worker.retry_in).to be >= worker.unique_in }
  end
end
