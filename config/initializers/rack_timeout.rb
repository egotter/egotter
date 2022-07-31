Rack::Timeout.register_state_change_observer(:a_unique_name) do |env|
  if env['rack-timeout.info'].state == :timed_out
    Airbag.warn 'Rack::Timeout.state_change_observer', state: :timed_out, REQUEST_URI: env&.fetch('REQUEST_URI', nil), HTTP_USER_AGENT: env&.fetch('HTTP_USER_AGENT', nil)
  end
end
