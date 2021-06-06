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

    def http_timeout?(ex)
      ex && ex.class.to_s.downcase.include?('timeout')
    end

    def could_not_parse_data?(ex)
      ex && ex.class == HTTP::ConnectionError && ex.message == 'error reading from socket: Could not parse data'
    end

    def could_not_read_response_headers?(ex)
      ex && ex.class == HTTP::ConnectionError && ex.message == "couldn't read response headers"
    end

    def unknown_mine_type?(ex)
      ex && ex.class == HTTP::Error && ex.message == 'Unknown MIME type: text/plain'
    end

    # OpenSSL::SSL::SSLError, SSL_connect SYSCALL returned=5 errno=0 state=SSLv2/v3 read server hello A
    # OpenSSL::SSL::SSLError, SSL_connect SYSCALL returned=5 errno=0 state=SSLv3 read server session ticket A
    def tls_handshake_failure?(ex)
      ex && ex.class == OpenSSL::SSL::SSLError
    end

    def retryable_error?(ex)
      connection_reset_by_peer?(ex) ||
          internal_server_error?(ex) ||
          service_unavailable?(ex) ||
          execution_expired?(ex) ||
          http_timeout?(ex) ||
          could_not_parse_data?(ex) ||
          could_not_read_response_headers?(ex) ||
          unknown_mine_type?(ex) ||
          tls_handshake_failure?(ex)
    end
  end
end
