# This file is used by Rack-based servers to start the application.

require 'unicorn/worker_killer'
use Unicorn::WorkerKiller::MaxRequests, 3072, 4096
use Unicorn::WorkerKiller::Oom, (192*(1024**2)), (256*(1024**2))

if ENV['STACKPROF_ENABLED'] == '1'
  require 'stackprof'
  use StackProf::Middleware, enabled: true, mode: :cpu, interval: 1000, save_every: 5
end

require ::File.expand_path('../config/environment', __FILE__)
run Rails.application
