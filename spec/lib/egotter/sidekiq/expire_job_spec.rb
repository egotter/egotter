require 'rails_helper'

RSpec.describe ExpireJob::Middleware do
  let(:middleware) { described_class.new }

  context 'Server side job running' do
    class TestExpireWorker
      include Sidekiq::Worker
      sidekiq_options queue: 'test', retry: 0, backtrace: false

      @@count = 0
      @@callback_count = 0

      def expire_in
        1.minute
      end

      def after_expire(*args)
        @@callback_count += 1
      end

      def perform(*args)
        @@count += 1
      end
    end

    before do
      Sidekiq::Testing.server_middleware do |chain|
        chain.add ExpireJob::Middleware
      end

      Redis.client.flushdb
      TestExpireWorker.clear
      TestExpireWorker.class_variable_set(:@@count, 0)
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
      expect(TestExpireWorker.class_variable_get(:@@count)).to eq(1)
      expect(TestExpireWorker.class_variable_get(:@@callback_count)).to eq(1)
    end

    specify 'Sidekiq server expires jobs with no enqueued_at specified' do
      expect(TestExpireWorker.jobs.size).to eq(0)

      TestExpireWorker.perform_async(1)
      expect(TestExpireWorker.jobs.size).to eq(1)

      travel 1.hour

      TestExpireWorker.drain
      expect(TestExpireWorker.jobs.size).to eq(0)
      expect(TestExpireWorker.class_variable_get(:@@count)).to eq(0)
      expect(TestExpireWorker.class_variable_get(:@@callback_count)).to eq(1)
    end
  end
end
