class SlackClient
  MONITORING               = ENV['SLACK_METRICS_WEBHOOK_URL']
  SIDEKIQ_MONITORING       = ENV['SLACK_SIDEKIQ_MONITORING_WEBHOOK_URL']
  TABLE_MONITORING         = ENV['SLACK_TABLE_MONITORING_WEBHOOK_URL']
  MESSAGING_MONITORING     = ENV['SLACK_MESSAGING_MONITORING_WEBHOOK_URL']
  VISITORS_MONITORING      = ENV['SLACK_VISITORS_MONITORING_WEBHOOK_URL']
  RATE_LIMIT_MONITORING    = ENV['SLACK_RATE_LIMIT_MONITORING_WEBHOOK_URL']
  SIGN_IN_MONITORING       = ENV['SLACK_SIGN_IN_MONITORING_WEBHOOK_URL']
  SEARCH_ERROR_MONITORING  = ENV['SLACK_SEARCH_ERROR_MONITORING_WEBHOOK_URL']
  TWITTER_USERS_MONITORING = ENV['SLACK_TWITTER_USERS_MONITORING_WEBHOOK_URL']
  USERS_MONITORING         = ENV['SLACK_USERS_MONITORING_WEBHOOK_URL']
  GA_MONITORING            = ENV['SLACK_GA_MONITORING_WEBHOOK_URL']
  SEARCH_HISTORIES_MONITORING = ENV['SLACK_SEARCH_HISTRIES_MONITORING_WEBHOOK_URL']

  class << self
    def send_message(text, title: nil, channel: MONITORING)
      text = format(text) if text.is_a?(Hash)
      text = "#{title}\n#{text}" if title
      HTTParty.post(channel, body: {text: text}.to_json)
    end

    def format(hash)
      text =
          if hash.empty?
            'Empty'
          else
            key_length = hash.keys.max_by {|k| k.to_s.length}.length
            hash.map do |key, value|
              sprintf("%#{key_length}s %s", key, value)
            end.join("\n")
          end

      "```\n" + text + "\n```"
    end
  end
end
