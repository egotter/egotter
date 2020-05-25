require 'rails_helper'

RSpec.describe TimeoutJob::Middleware do
  context 'Server side job running' do
    class TestTimeoutWorker
      include Sidekiq::Worker
      sidekiq_options queue: 'test', retry: 0, backtrace: false

      @@count = 0
      @@callback_count = 0

      def timeout_in
        0.1
      end

      def after_timeout(*args)
        @@callback_count += 1
      end

      def perform(*args)
        sleep 1
        @@count += 1
      end
    end

    before do
      Sidekiq::Testing.server_middleware do |chain|
        chain.add TimeoutJob::Middleware
      end

      Redis.client.flushdb
      TestTimeoutWorker.clear
      TestTimeoutWorker.class_variable_set(:@@count, 0)
      TestTimeoutWorker.class_variable_set(:@@callback_count, 0)
    end

    specify 'Sidekiq server terminates long-running jobs' do
      expect(TestTimeoutWorker.jobs.size).to eq(0)

      TestTimeoutWorker.perform_async(1)
      expect(TestTimeoutWorker.jobs.size).to eq(1)

      TestTimeoutWorker.drain
      expect(TestTimeoutWorker.class_variable_get(:@@count)).to eq(0)
      expect(TestTimeoutWorker.class_variable_get(:@@callback_count)).to eq(1)
    end
  end
end
