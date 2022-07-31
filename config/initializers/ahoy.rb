class Ahoy::Store < Ahoy::DatabaseStore
end

# set to true for JavaScript tracking
Ahoy.api = false

# better user agent parsing
Ahoy.user_agent_parser = :device_detector

# better bot detection
# Ahoy.bot_detection_version = 2

Ahoy.track_bots = true

Ahoy.visit_duration = 30.minutes

Ahoy.geocode = false

Safely.report_exception_method = Proc.new do |e, context|
  Airbag.exception e, location: 'Safely.report_exception_method', context: context
end
