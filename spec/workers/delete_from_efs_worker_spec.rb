require 'rails_helper'

RSpec.describe DeleteFromEfsWorker do
  describe '.remove_and_perform_in' do
    before do
      Redis.client.flushdb
      described_class.clear
    end

    it do
      Sidekiq::Testing.disable! do
        expect(Sidekiq::ScheduledSet.new.size).to eq(0)

        described_class.perform_in(1.hour, 'klass' => 'klass1', 'key' => 1)
        expect(Sidekiq::ScheduledSet.new.size).to eq(1)

        described_class.perform_in(1.hour, 'klass' => 'klass1', 'key' => 2)
        expect(Sidekiq::ScheduledSet.new.size).to eq(2)

        described_class.perform_in(1.hour, 'klass' => 'klass2', 'key' => 1)
        expect(Sidekiq::ScheduledSet.new.size).to eq(3)

        described_class.perform_in(1.hour, 'klass' => 'klass2', 'key' => 1)
        expect(Sidekiq::ScheduledSet.new.size).to eq(3)

        described_class.perform_in(1.hour, 'klass' => 'klass1', 'key' => 2)
        expect(Sidekiq::ScheduledSet.new.size).to eq(3)
      end
    end
  end
end
