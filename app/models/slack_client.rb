class SlackClient
  MONITORING = ENV['SLACK_METRICS_WEBHOOK_URL']
  SIDEKIQ_MONITORING = ENV['SLACK_SIDEKIQ_MONITORING_WEBHOOK_URL']
  TABLE_MONITORING = ENV['SLACK_TABLE_MONITORING_WEBHOOK_URL']
  MESSAGING_MONITORING = ENV['SLACK_MESSAGING_MONITORING_WEBHOOK_URL']
  VISITORS_MONITORING = ENV['SLACK_VISITORS_MONITORING_WEBHOOK_URL']
  RATE_LIMIT_MONITORING = ENV['SLACK_RATE_LIMIT_MONITORING_WEBHOOK_URL']
  SIGN_IN_MONITORING = ENV['SLACK_SIGN_IN_MONITORING_WEBHOOK_URL']
  SEARCH_ERROR_MONITORING = ENV['SLACK_SEARCH_ERROR_MONITORING_WEBHOOK_URL']

  class << self
    def send_message(text, channel: MONITORING)
      HTTParty.post(channel, body: {text: text}.to_json)
    end

    def format(hash)
      text =
          if hash.empty?
            'Empty'
          else
            key_length = hash.keys.max_by {|k| k.length}.length
            hash.map do |key, value|
              sprintf("%#{key_length}s %s", key, value)
            end.join("\n")
          end

      "```\n" + text + "\n```"
    end
  end
end
