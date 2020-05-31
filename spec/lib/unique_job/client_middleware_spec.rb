require 'rails_helper'

RSpec.describe UniqueJob::ClientMiddleware do
  let(:middleware) { described_class.new }

  class Worker
  end

  describe '#call' do
    let(:worker_str) { Worker.to_s }
    let(:job) { {'args' => 'args'} }

    context 'job has the "at" key' do
      before { job['at'] = 'ok' }
      it { expect { |b| middleware.call(worker_str, job, nil, nil, &b) }.to yield_control }
    end

    context 'job doesn\'t have the "at" key' do
      let(:block) { Proc.new {} }
      it do
        expect(middleware).to receive(:perform_if_unique).with(instance_of(Worker), job['args']) do |&blk|
          expect(blk).to be(block)
        end
        middleware.call(worker_str, job, nil, nil, &block)
      end
    end
  end

  context 'Client side job queueing' do
    class TestClientWorker
      include Sidekiq::Worker
      sidekiq_options queue: 'test', retry: 0, backtrace: false

      @@callback_count = 0

      def unique_key(*args)
        args[0]
      end

      def unique_in
        1.minute
      end

      def after_skip(*args)
        @@callback_count += 1
      end

      def perform(*args)
        raise
      end
    end

    before do
      Redis.client.flushdb
      TestClientWorker.clear
      TestClientWorker.class_variable_set(:@@callback_count, 0)
    end

    let(:args) { [1] }

    specify "Sidekiq client doesn't push jobs that have the same unique_key" do
      expect(TestClientWorker.jobs.size).to eq(0)

      TestClientWorker.perform_async(*args)
      expect(TestClientWorker.jobs.size).to eq(1)
      expect(TestClientWorker.class_variable_get(:@@callback_count)).to eq(0)

      TestClientWorker.perform_async(*args)
      expect(TestClientWorker.jobs.size).to eq(1)
      expect(TestClientWorker.class_variable_get(:@@callback_count)).to eq(1)
    end

    context 'after the specified time has elapsed' do
      specify 'Sidekiq client pushes jobs that have the same unique_key' do
        expect(TestClientWorker.jobs.size).to eq(0)

        TestClientWorker.perform_async(*args)
        expect(TestClientWorker.jobs.size).to eq(1)
        expect(TestClientWorker.class_variable_get(:@@callback_count)).to eq(0)

        TestClientWorker.perform_async(*args)
        expect(TestClientWorker.jobs.size).to eq(1)
        expect(TestClientWorker.class_variable_get(:@@callback_count)).to eq(1)

        UniqueJob::JobHistory.new(TestClientWorker, described_class, nil).delete_all

        TestClientWorker.perform_async(*args)
        expect(TestClientWorker.jobs.size).to eq(2)
        expect(TestClientWorker.class_variable_get(:@@callback_count)).to eq(1)
      end
    end

    context 'if the time is specified' do
      specify 'Sidekiq client pushes jobs that have the same unique_key' do
        Sidekiq::Testing.disable! do
          expect(Sidekiq::ScheduledSet.new.size).to eq(0)

          TestClientWorker.perform_in(1.minute, *args)
          expect(Sidekiq::ScheduledSet.new.size).to eq(1)
          expect(TestClientWorker.class_variable_get(:@@callback_count)).to eq(0)

          TestClientWorker.perform_in(1.minute, *args)
          expect(Sidekiq::ScheduledSet.new.size).to eq(2)
          expect(TestClientWorker.class_variable_get(:@@callback_count)).to eq(0)
        end
      end
    end
  end
end
