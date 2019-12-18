require 'sidekiq/testing'
Sidekiq::Testing.fake!
Sidekiq.logger.level = Logger::ERROR
