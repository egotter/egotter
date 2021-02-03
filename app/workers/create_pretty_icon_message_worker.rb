class CreatePrettyIconMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  TEXT = [
      'ありがとう！',
      '嬉しいです！',
  ]

  KAOMOJI = [
      'Σ(-᷅_-᷄๑)',
      '`⁽˙꒳˙⁾´',
      '( ･ᴗ･ )',
      '( ੭ ･ᴗ･ )੭',
      '( ´•ᴗ•ก)',
      'ᕱ⑅ᕱ',
      '(๑•ᴗ•๑)',
      '❀.(*´▽`*)❀',
  ]

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    30.seconds
  end

  # options:
  def perform(uid, options = {})
    message = TEXT.sample + KAOMOJI.sample
    User.egotter.api_client.create_direct_message_event(uid, message)
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end
end
