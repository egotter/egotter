class ServiceStatus
  def initialize(ex: nil)
    @ex = ex
  end

  def connection_reset_by_peer?
    # Errno::ECONNRESET
    # HTTP::ConnectionError
    # Twitter::Error
    @ex && @ex.message.include?('Connection reset by peer')
  end

  def internal_server_error?
    @ex && @ex.class == Twitter::Error::InternalServerError && ['Internal error', ''].include?(@ex.message)
  end

  def service_unavailable?
    @ex && @ex.class == Twitter::Error::ServiceUnavailable && ['Over capacity', ''].include?(@ex.message)
  end

  def execution_expired?
    @ex && @ex.class == Twitter::Error && @ex.message == 'execution expired'
  end

  def retryable?
    connection_reset_by_peer? || internal_server_error? || service_unavailable? || execution_expired?
  end

  class << self
    def internal_server_error?(ex)
      new(ex: ex).internal_server_error?
    end

    def service_unavailable?(ex)
      new(ex: ex).service_unavailable?
    end

    def retryable?(ex)
      new(ex: ex).retryable?
    end
  end
end
