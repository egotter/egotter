# This file is used by Rack-based servers to start the application.

if ENV['STACKPROF'] == '1'
  require 'stackprof'
  use StackProf::Middleware, enabled: true, mode: :cpu, interval: 1000, save_every: 5
end

require ::File.expand_path('../config/environment', __FILE__)
run Rails.application
