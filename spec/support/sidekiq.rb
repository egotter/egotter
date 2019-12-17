require 'sidekiq/testing'
Sidekiq::Testing.fake!

Sidekiq::Testing.server_middleware do |chain|
  chain.add Egotter::Sidekiq::ServerUniqueJob, 'test server'
  chain.add Egotter::Sidekiq::ExpireJob
  chain.add Egotter::Sidekiq::TimeoutJob
end
