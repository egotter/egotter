class Ahoy::Store < Ahoy::DatabaseStore
end

# set to true for JavaScript tracking
Ahoy.api = false

# better user agent parsing
Ahoy.user_agent_parser = :device_detector

# better bot detection
# Ahoy.bot_detection_version = 2

Ahoy.track_bots = true

Ahoy.exclude_method = lambda do |controller, request|
  controller.from_crawler?
rescue => e
  Rails.logger.warn "controller doesn't respond to #from_crawler? #{controller.class} #{request.fullpath} #{request.referer}"
  raise
end

Ahoy.visit_duration = 30.minutes

Ahoy.geocode = false
