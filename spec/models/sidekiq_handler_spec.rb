require 'rails_helper'

RSpec.describe SidekiqHandler, type: :model do
  describe '.queue' do
    it 'returns Sidekiq::Queue' do
      expect(SidekiqHandler.queue).to an_instance_of(Sidekiq::Queue)
    end
  end

  describe '.latency' do
    it 'returns Integer' do
      expect(SidekiqHandler.latency.is_a?(Integer)).to be_truthy
    end
  end

  describe '.delay_occurs?' do
    it 'returns Boolean' do
      expect(SidekiqHandler.delay_occurs?.in?([true, false])).to be_truthy
    end
  end

  describe '.stats' do
    it 'returns Sidekiq::Stats' do
      expect(SidekiqHandler.stats).to an_instance_of(Sidekiq::Stats)
    end
  end

  describe '.process_set' do
    it 'returns Sidekiq::ProcessSet' do
      expect(SidekiqHandler.process_set).to an_instance_of(Sidekiq::ProcessSet)
    end
  end

  describe '.workers' do
    it 'returns Sidekiq::Workers' do
      expect(SidekiqHandler.workers).to an_instance_of(Sidekiq::Workers)
    end
  end
end
