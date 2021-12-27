class CreateDirectMessageErrorLog2Worker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    DirectMessageErrorLog.create!(attrs)
  rescue => e
    Airbag.warn "#{e.inspect} attrs=#{attrs.inspect}"
  end
end
