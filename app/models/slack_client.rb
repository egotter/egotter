class SlackClient
  URLS = {
      monitoring:                  ENV['SLACK_METRICS_WEBHOOK_URL'],
      sidekiq_monitoring:          ENV['SLACK_SIDEKIQ_MONITORING_WEBHOOK_URL'],
      table_monitoring:            ENV['SLACK_TABLE_MONITORING_WEBHOOK_URL'],
      messaging_monitoring:        ENV['SLACK_MESSAGING_MONITORING_WEBHOOK_URL'],
      visitors_monitoring:         ENV['SLACK_VISITORS_MONITORING_WEBHOOK_URL'],
      rate_limit_monitoring:       ENV['SLACK_RATE_LIMIT_MONITORING_WEBHOOK_URL'],
      sign_in_monitoring:          ENV['SLACK_SIGN_IN_MONITORING_WEBHOOK_URL'],
      search_error_monitoring:     ENV['SLACK_SEARCH_ERROR_MONITORING_WEBHOOK_URL'],
      twitter_users_monitoring:    ENV['SLACK_TWITTER_USERS_MONITORING_WEBHOOK_URL'],
      users_monitoring:            ENV['SLACK_USERS_MONITORING_WEBHOOK_URL'],
      ga_monitoring:               ENV['SLACK_GA_MONITORING_WEBHOOK_URL'],
      search_histories_monitoring: ENV['SLACK_SEARCH_HISTRIES_MONITORING_WEBHOOK_URL'],
      test_messages:               ENV['SLACK_TEST_MESSAGES_URL'],
      bot:                         ENV['SLACK_BOT_URL'],
  }

  def initialize(webhook:)
    @webhook = webhook
  end

  def send_message(text, title: nil)
    text = format(text) if text.is_a?(Hash)
    text = "#{title}\n#{text}" if title
    HTTParty.post(@webhook, body: {text: text}.to_json)
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

  class << self
    def method_missing(method, *args)
      if URLS[method]
        new(webhook: URLS[method])
      else
        super
      end
    end
  end
end
