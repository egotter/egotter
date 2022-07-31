# There is no request timeout mechanism inside of Puma.
# rack-timeout 15, proxy_read_timeout(nginx) 35

environment 'production'
threads 10, 10
workers 2
pidfile "#{Dir.pwd}/tmp/pids/puma.pid"
state_path "#{Dir.pwd}/tmp/pids/puma.state"
bind 'unix:///tmp/puma.sock'
stdout_redirect "#{Dir.pwd}/log/puma.log", "#{Dir.pwd}/log/puma.log", true
preload_app!

lowlevel_error_handler do |e, env, status|
  Airbag.exception e, location: 'Puma.lowlevel_error_handler', status: status, REQUEST_URI: env&.fetch('REQUEST_URI', nil), HTTP_USER_AGENT: env&.fetch('HTTP_USER_AGENT', nil)
  [500, {}, ["An error has occurred.\n"]]
rescue => ee
  Rails.logger.error "Puma.lowlevel_error_handler: #{ee.inspect}"
  Rails.logger.error "Puma.lowlevel_error_handler: #{ee.backtrace.join("\n")}"
  if ee.cause
    Rails.logger.error "Puma.lowlevel_error_handler: cause: #{ee.cause.inspect}"
    Rails.logger.error "Puma.lowlevel_error_handler: cause: #{ee.cause.backtrace.join("\n")}"
  end
  [500, {}, ["An error has occurred.\n"]]
end
