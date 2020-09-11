class ServiceStatus
  class << self
    def connection_reset_by_peer?(ex)
      # Errno::ECONNRESET
      # HTTP::ConnectionError
      # Twitter::Error
      ex && ex.message.include?('Connection reset by peer')
    end

    def internal_server_error?(ex)
      ex && ex.class == Twitter::Error::InternalServerError && ['Internal error', ''].include?(ex.message)
    end

    def service_unavailable?(ex)
      ex && ex.class == Twitter::Error::ServiceUnavailable && ['Over capacity', ''].include?(ex.message)
    end

    def execution_expired?(ex)
      ex && ex.class == Twitter::Error && ex.message == 'execution expired'
    end

    def retryable_error?(ex)
      connection_reset_by_peer?(ex) || internal_server_error?(ex) || service_unavailable?(ex) || execution_expired?(ex)
    end
  end
end
