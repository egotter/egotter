require 'rails_helper'

RSpec.describe Egotter::Sidekiq::ServerUniqueJob do
  let(:queue_class) { Egotter::Sidekiq::RunHistory }
  let(:middleware) { described_class.new }

  describe '#initialize' do
    it do
      expect(middleware.instance_variable_get(:@queue_class)).to eq(queue_class)
      expect(middleware.instance_variable_get(:@queueing_context)).to eq('server')
    end
  end

  describe '#call' do
    let(:worker) { double('Worker') }
    let(:msg) { {'args' => [1, 2, 3]} }
    let(:history) { double('History') }
    let(:queueing_context) { 'server' }
    let(:block) { Proc.new {} }

    it do
      expect(middleware).to receive(:run_history).with(worker, queue_class, queueing_context).and_return(history)
      expect(middleware).to receive(:perform).with(worker, msg['args'], history) { |&blk| expect(blk).to be(block) }
      middleware.call(worker, msg, nil, &block)
    end
  end

  context 'Server side job running' do
    class TestServerWorker
      include Sidekiq::Worker
      sidekiq_options queue: 'test', retry: 0, backtrace: false

      @@count = 0
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
        @@count += 1
      end
    end

    before do
      Sidekiq::Testing.server_middleware do |chain|
        chain.add Egotter::Sidekiq::ServerUniqueJob, 'test server'
      end

      Redis.client.flushdb
      TestServerWorker.clear
      TestServerWorker.class_variable_set(:@@count, 0)
      TestServerWorker.class_variable_set(:@@callback_count, 0)
    end

    specify "Sidekiq server doesn't run jobs that have the same unique_key" do
      expect(TestServerWorker.jobs.size).to eq(0)

      TestServerWorker.perform_async(1)
      expect(TestServerWorker.jobs.size).to eq(1)

      travel TestServerWorker.new.unique_in

      TestServerWorker.perform_async(1)
      expect(TestServerWorker.jobs.size).to eq(2)

      TestServerWorker.drain
      expect(TestServerWorker.jobs.size).to eq(0)
      expect(TestServerWorker.class_variable_get(:@@count)).to eq(1)
      expect(TestServerWorker.class_variable_get(:@@callback_count)).to eq(1)
    end

    specify 'Sidekiq server runs jobs that have the same unique_key after the specified time has elapsed' do
      expect(TestServerWorker.jobs.size).to eq(0)

      TestServerWorker.perform_async(1)
      expect(TestServerWorker.jobs.size).to eq(1)

      TestServerWorker.drain
      expect(TestServerWorker.jobs.size).to eq(0)
      expect(TestServerWorker.class_variable_get(:@@count)).to eq(1)
      expect(TestServerWorker.class_variable_get(:@@callback_count)).to eq(0)

      travel TestServerWorker.new.unique_in

      TestServerWorker.perform_async(1)
      expect(TestServerWorker.jobs.size).to eq(1)

      TestServerWorker.drain
      expect(TestServerWorker.jobs.size).to eq(0)
      expect(TestServerWorker.class_variable_get(:@@count)).to eq(2)
      expect(TestServerWorker.class_variable_get(:@@callback_count)).to eq(0)
    end
  end
end
