module LoggingWrapper
  def perform(*args)
    super
  rescue ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.inspect)
  rescue => e
    Airbag.exception e, args: args
  end

  class StatementInvalid < StandardError
  end
end
