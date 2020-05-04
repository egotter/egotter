require 'rails_helper'

RSpec.describe CreatePromptReportWorker do

  # describe '#perform' do
  #   let(:args) { [1, {a: 1}] }
  #   subject { described_class.new.perform(*args) }
  #   before { allow(CallCreateDirectMessageEventCount).to receive(:rate_limited?).and_return(true) }
  #
  #   it do
  #     expect(SkippedCreatePromptReportWorker).to receive(:perform_async).with(*args)
  #     subject
  #   end
  # end

  describe '.consume_skipped_jobs' do
    # TODO Add test cases
  end
end
