class Ahoy::Store < Ahoy::DatabaseStore
  def track_event(data)
    visit = visit_or_create(started_at: data[:time])
    if visit
      event = event_model.new(slice_data(event_model, data))
      event.visit = visit
      event.time = visit.started_at if event.time < visit.started_at
      CreateAhoyEventWorker.perform_async(event.attributes.except('id'))
    else
      Ahoy.log "Event excluded since visit not created: #{data[:visit_token]}"
    end
  rescue => e
    Airbag.exception e, location: 'Ahoy::Store#track_event', data: data
  end
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

Rails.application.reloader.to_prepare do
  Ahoy::EventsController.include(RequestErrorHandler)
end
