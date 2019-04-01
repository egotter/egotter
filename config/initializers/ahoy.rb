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
  # After signing in, Devise calls callbacks without controller.
  unless controller.nil?
    controller.from_crawler?
  end
rescue => e
  Rails.logger.warn "in ahoy.rb something happened. #{e.class} #{e.message} #{controller.class} #{request.fullpath} #{request.referer}"
  raise
end

Ahoy.visit_duration = 30.minutes

Ahoy.geocode = false
