require 'rails_helper'

RSpec.describe ResetEgotterWorker do
  module DoNothingWorker
    def perform(*args)
    end
  end

  before do
    Sidekiq::Worker.clear_all
  end

  describe '#unique_key' do
    let(:request_id) { 1 }
    let(:queueing_requests) { QueueingRequests.new(described_class) }
    let(:running_queue) { RunningQueue.new(described_class) }

    before do
      described_class.send(:prepend, DoNothingWorker)
      queueing_requests.clear
      running_queue.clear
    end

    it do
      expect(queueing_requests.to_a).to be_empty
      expect(running_queue.to_a).to be_empty

      expect(described_class.jobs.size).to eq(0)
      described_class.perform_async(request_id)
      expect(described_class.jobs.size).to eq(1)
      described_class.drain
      expect(described_class.jobs.size).to eq(0)

      expect(queueing_requests.to_a).to match_array([request_id.to_s])
      expect(running_queue.to_a).to match_array([request_id.to_s])
    end
  end

  describe '#after_timeout' do

  end
end
