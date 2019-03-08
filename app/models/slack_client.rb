class SlackClient
  MONITORING = ENV['SLACK_METRICS_WEBHOOK_URL']
  SIDEKIQ_MONITORING = ENV['SLACK_SIDEKIQ_MONITORING_WEBHOOK_URL']
  TABLE_MONITORING = ENV['SLACK_TABLE_MONITORING_WEBHOOK_URL']

  class << self
    def send_message(text, channel: MONITORING)
      HTTParty.post(channel, body: {text: '-- start --'}.to_json) if Rails.env.development?
      HTTParty.post(channel, body: {text: text}.to_json)
      HTTParty.post(channel, body: {text: '-- end --'}.to_json) if Rails.env.development?
    end
  end
end
