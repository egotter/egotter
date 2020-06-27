class OmniauthLogger < ::Logger
  def initialize(*args)
    super
    self.formatter = ::Logger::Formatter.new
  end

  def error(*args)
    if session_expired?(args[0]) || invalid_credentials?(args[0])
      info(*args)
    else
      super
    end
  rescue => e
    super
  end

  private

  def session_expired?(str)
    str.include?('(twitter) Authentication failure! session_expired: OmniAuth::NoSessionError')
  end

  def invalid_credentials?(str)
    str.include?('(twitter) Authentication failure! invalid_credentials: OAuth::Unauthorized')
  end
end

OmniAuth.config.logger = OmniauthLogger.new(STDOUT)
