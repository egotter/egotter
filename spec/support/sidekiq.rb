require 'sidekiq/testing'
Sidekiq::Testing.fake!

Sidekiq::Testing.server_middleware do |chain|
  chain.add SidekiqServerUniqueJob, RunningQueue
  chain.add SidekiqExpireJob
  chain.add SidekiqTimeoutJob
end
