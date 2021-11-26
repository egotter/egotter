require 'rails_helper'

RSpec.describe UniqueJob::ServerMiddleware do
  let(:middleware) { described_class.new(host: ENV['REDIS_HOST'], db: 1) }

  describe '#call' do
    let(:msg) { {'args' => 'args'} }
    let(:block) { Proc.new {} }

    subject { middleware.call('worker', msg, nil, &block) }

    it do
      expect(middleware).to receive(:perform_if_unique).with('worker', msg['args']) { |&blk| expect(blk).to be(block) }
      subject
    end
  end

  context 'Server side job running' do
    class TestServerWorker
      include Sidekiq::Worker
      sidekiq_options queue: 'test', retry: 0, backtrace: false

      @@perform_count = 0
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
        @@perform_count += 1
      end
    end

    before do
      Sidekiq::Testing.server_middleware do |chain|
        chain.add UniqueJob::ServerMiddleware, {host: ENV['REDIS_HOST'], db: 1}
      end

      Redis.new(host: ENV['REDIS_HOST']).flushall
      TestServerWorker.clear
      TestServerWorker.class_variable_set(:@@perform_count, 0)
      TestServerWorker.class_variable_set(:@@callback_count, 0)
    end

    specify "Sidekiq server doesn't run jobs that have the same unique_key" do
      expect(TestServerWorker.jobs.size).to eq(0)

      TestServerWorker.perform_async(1)
      expect(TestServerWorker.jobs.size).to eq(1)

      UniqueJob::JobHistory.new(TestServerWorker, UniqueJob::ClientMiddleware, nil).delete_all

      TestServerWorker.perform_async(1)
      expect(TestServerWorker.jobs.size).to eq(2)

      UniqueJob::JobHistory.new(TestServerWorker, UniqueJob::ClientMiddleware, nil).delete_all

      TestServerWorker.drain
      expect(TestServerWorker.jobs.size).to eq(0)
      expect(TestServerWorker.class_variable_get(:@@perform_count)).to eq(1)
      expect(TestServerWorker.class_variable_get(:@@callback_count)).to eq(1)
    end

    context 'after the specified time has elapsed' do
      specify 'Sidekiq server runs jobs that have the same unique_key' do
        expect(TestServerWorker.jobs.size).to eq(0)

        TestServerWorker.perform_async(1)
        expect(TestServerWorker.jobs.size).to eq(1)

        TestServerWorker.drain
        expect(TestServerWorker.jobs.size).to eq(0)
        expect(TestServerWorker.class_variable_get(:@@perform_count)).to eq(1)
        expect(TestServerWorker.class_variable_get(:@@callback_count)).to eq(0)

        UniqueJob::JobHistory.new(TestServerWorker, UniqueJob::ClientMiddleware, nil).delete_all
        UniqueJob::JobHistory.new(TestServerWorker, described_class, nil).delete_all

        TestServerWorker.perform_async(1)
        expect(TestServerWorker.jobs.size).to eq(1)

        TestServerWorker.drain
        expect(TestServerWorker.jobs.size).to eq(0)
        expect(TestServerWorker.class_variable_get(:@@perform_count)).to eq(2)
        expect(TestServerWorker.class_variable_get(:@@callback_count)).to eq(0)
      end
    end
  end
end
