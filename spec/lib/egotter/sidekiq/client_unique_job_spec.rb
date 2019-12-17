require 'rails_helper'

RSpec.describe Egotter::Sidekiq::ClientUniqueJob do
  let(:queue_class) { Egotter::Sidekiq::RunHistory }
  let(:middleware) { described_class.new }

  class Worker
  end

  describe '#initialize' do
    it do
      expect(middleware.instance_variable_get(:@queue_class)).to eq(queue_class)
      expect(middleware.instance_variable_get(:@queueing_context)).to eq('client')
    end
  end

  describe '#call' do
    let(:worker_str) { Worker.to_s }
    let(:job) { {'args' => [1, 2, 3]} }

    context 'job has the "at" key' do
      before { job['at'] = 'ok' }
      it { expect { |b| middleware.call(worker_str, job, nil, nil, &b) }.to yield_control }
    end

    context 'job doesn\'t have the "at" key' do
      let(:block) { Proc.new {} }
      it do
        expect(middleware).to receive(:run_history).with(instance_of(Worker), queue_class, 'client').and_return('ok')
        expect(middleware).to receive(:perform).with(instance_of(Worker), job['args'], 'ok') do |&blk|
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

      def unique_key(*args)
        args[0]
      end

      def unique_in
        1.minute
      end
    end

    before do
      Redis.client.flushdb
      TestClientWorker.clear
      TestClientWorker.class_variable_set(:@@count, 0)
    end

    specify "Sidekiq client doesn't push jobs that have the same unique_key" do
      expect(TestClientWorker.jobs.size).to eq(0)

      TestClientWorker.perform_async(1)
      expect(TestClientWorker.jobs.size).to eq(1)

      TestClientWorker.perform_async(1)
      expect(TestClientWorker.jobs.size).to eq(1)
    end

    specify 'Sidekiq client pushes jobs that have the same unique_key after the specified time has elapsed' do
      expect(TestClientWorker.jobs.size).to eq(0)

      TestClientWorker.perform_async(1)
      expect(TestClientWorker.jobs.size).to eq(1)

      TestClientWorker.perform_async(1)
      expect(TestClientWorker.jobs.size).to eq(1)

      travel TestClientWorker.new.unique_in

      TestClientWorker.perform_async(1)
      expect(TestClientWorker.jobs.size).to eq(2)
    end

    context 'Scheduled jobs' do
      specify 'Sidekiq client pushes jobs that have the same unique_key if the time is scheduled' do
        Sidekiq::Testing.disable! do
          expect(Sidekiq::ScheduledSet.new.size).to eq(0)

          TestClientWorker.perform_in(1.minute, 1)
          expect(Sidekiq::ScheduledSet.new.size).to eq(1)

          TestClientWorker.perform_in(1.minute, 1)
          expect(Sidekiq::ScheduledSet.new.size).to eq(2)
        end
      end
    end
  end
end
