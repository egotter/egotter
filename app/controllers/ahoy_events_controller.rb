require 'timeout'

# Ahoy::EventsController
class AhoyEventsController < Ahoy::BaseController
  # include RequestErrorHandler

  def create
    timeout = 5
    start = Time.zone.now

    events =
        if params[:name]
          # legacy API and AMP
          [request.params]
        elsif params[:events]
          request.params[:events]
        else
          data =
              if params[:events_json]
                request.params[:events_json]
              else
                begin
                  Timeout.timeout(timeout) do
                    request.body.read
                  end
                rescue Timeout::Error => e
                  log 'Timeout while reading request.body'
                  '[]'
                end
              end
          begin
            Timeout.timeout(timeout) do
              ActiveSupport::JSON.decode(data)
            end
          rescue Timeout::Error => e
            log "Timeout while decoding data size=#{data.size}"
            []
          rescue ActiveSupport::JSON.parse_error
            # do nothing
            []
          end
        end

    if Time.zone.now - start > timeout
      log "Timeout before creating events total=#{events.size}"
      render json: {}
      return
    end

    events.first(Ahoy.max_events_per_request).each.with_index do |event, i|
      time = Time.zone.parse(event["time"]) rescue nil

      # timestamp is deprecated
      time ||= Time.zone.at(event["time"].to_f) rescue nil

      options = {
          id: event["id"],
          time: time
      }
      ahoy.track event["name"], event["properties"], options

      if Time.zone.now - start > timeout
        log "Timeout while creating events created=#{i + 1} total=#{events.size} max=#{Ahoy.max_events_per_request}"
        break
      end
    end
    render json: {}
  end

  def log(message)
    Airbag.warn "AhoyEventsController: #{message}"
  end
end
