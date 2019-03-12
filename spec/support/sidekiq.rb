require 'sidekiq/testing'
Sidekiq::Testing.fake!

Sidekiq::Testing.server_middleware do |chain|
  chain.add Egotter::Sidekiq::ServerUniqueJob, RunningQueue
  chain.add Egotter::Sidekiq::ExpireJob
  chain.add Egotter::Sidekiq::TimeoutJob
end
