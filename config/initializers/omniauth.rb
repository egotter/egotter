class OmniauthLogger < ::Logger
  def initialize(*args)
    super
    self.formatter = ::Logger::Formatter.new
  end

  def error(*args)
    if args[0].starts_with?('omniauth: (twitter) Authentication failure! session_expired:')
      info(*args)
    else
      super
    end
  rescue => e
    super
  end
end

OmniAuth.config.logger = OmniauthLogger.new(STDOUT)
