require 'rails_helper'

RSpec.describe ExpireJob::Middleware do
  context 'Server side job running' do
    class TestExpireWorker
      include Sidekiq::Worker
      sidekiq_options queue: 'test', retry: 0, backtrace: false

      @@perform_count = 0
      @@callback_count = 0

      def expire_in
        1.minute
      end

      def after_expire(*args)
        @@callback_count += 1
      end

      def perform(*args)
        @@perform_count += 1
      end
    end

    before do
      Sidekiq::Testing.server_middleware do |chain|
        chain.add ExpireJob::Middleware
      end

      Redis.new(host: ENV['REDIS_HOST']).flushall
      TestExpireWorker.clear
      TestExpireWorker.class_variable_set(:@@perform_count, 0)
      TestExpireWorker.class_variable_set(:@@callback_count, 0)
    end

    specify "Sidekiq server doesn't run jobs that have a expired enqueued_at" do
      expect(TestExpireWorker.jobs.size).to eq(0)

      TestExpireWorker.perform_async(1, enqueued_at: Time.zone.now)
      expect(TestExpireWorker.jobs.size).to eq(1)

      TestExpireWorker.perform_async(1, enqueued_at: 1.hour.ago)
      expect(TestExpireWorker.jobs.size).to eq(2)

      TestExpireWorker.drain
      expect(TestExpireWorker.jobs.size).to eq(0)
      expect(TestExpireWorker.class_variable_get(:@@perform_count)).to eq(1)
      expect(TestExpireWorker.class_variable_get(:@@callback_count)).to eq(1)
    end

    context 'Even if no value is explicitly specified' do
      specify 'Sidekiq server expires jobs' do
        expect(TestExpireWorker.jobs.size).to eq(0)

        TestExpireWorker.perform_async(1)
        expect(TestExpireWorker.jobs.size).to eq(1)

        travel 1.hour

        TestExpireWorker.drain
        expect(TestExpireWorker.jobs.size).to eq(0)
        expect(TestExpireWorker.class_variable_get(:@@perform_count)).to eq(0)
        expect(TestExpireWorker.class_variable_get(:@@callback_count)).to eq(1)
      end
    end
  end
end
