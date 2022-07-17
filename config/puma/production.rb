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

lowlevel_error_handler do |e|
  Airbag.error "Puma.lowlevel_error_handler: #{e.inspect.truncate(200)}", backtrace: e.backtrace
  [500, {}, ["An error has occurred.\n"]]
rescue => ee
  Rails.logger.error "Puma.lowlevel_error_handler: original=#{e.inspect.truncate(200)} current=#{ee.inspect.truncate(200)}"
  [500, {}, ["An error has occurred.\n"]]
end
