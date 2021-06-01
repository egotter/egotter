require 'net/http'

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
      welcome_messages:            ENV['SLACK_WELCOME_MESSAGES_URL'],
      received_messages:           ENV['SLACK_RECEIVED_MESSAGES_URL'],
      sent_messages:               ENV['SLACK_SENT_MESSAGES_URL'],
      continue_notif_messages:     ENV['SLACK_CONTINUE_NOTIF_MESSAGES_URL'],
      bot:                         ENV['SLACK_BOT_URL'],
      tweet:                       ENV['SLACK_TWEET_URL'],
      reset_egotter:               ENV['SLACK_RESET_EGOTTER_URL'],
      reset_cache:                 ENV['SLACK_RESET_CACHE_URL'],
      delete_tweets:               ENV['SLACK_DELETE_TWEETS_URL'],
      delete_favorites:            ENV['SLACK_DELETE_FAVORITES_URL'],
      orders:                      ENV['SLACK_ORDERS_URL'],
      orders_cs_created:           ENV['SLACK_ORDERS_CS_CREATED_URL'],
      orders_cs_completed:         ENV['SLACK_ORDERS_CS_COMPLETED_URL'],
      orders_charge_succeeded:     ENV['SLACK_ORDERS_CHARGE_SUCCEEDED_URL'],
      orders_charge_failed:        ENV['SLACK_ORDERS_CHARGE_FAILED_URL'],
      deploy:                      ENV['SLACK_DEPLOY_URL'],
  }

  class << self
    URLS.each do |name, url|
      define_method(name) do |*args, &blk|
        new(webhook: url)
      end
    end

    def channel(name)
      send(name)
    end
  end

  def initialize(webhook:)
    @webhook = webhook
  end

  def send_message(text, title: nil)
    text = format(text) if text.is_a?(Hash)
    text = "#{title}\n#{text}" if title
    perform_request({text: text})
  end

  def send_context_message(text, screen_name, icon_url, urls)
    mrkdwn_text = urls.map.with_index { |url, i| "<#{url}|url#{i + 1}>" }.join(' ') + ' ' + text
    block = {
        type: 'context',
        elements: [
            {type: 'image', image_url: icon_url, alt_text: "@#{screen_name}"},
            {type: 'mrkdwn', text: mrkdwn_text}
        ],
    }
    perform_request({blocks: [block]})
  end

  private

  def perform_request(request_body, retries: 3)
    uri = URI.parse(@webhook)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.open_timeout = 3
    https.read_timeout = 3
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req['User-Agent'] = 'egotter'
    req.body = request_body.to_json
    https.start { https.request(req) }.body
  rescue Net::ReadTimeout => e
    if (retries -= 1) >= 0
      sleep(rand(3) + 1)
      retry
    else
      raise RetryExhausted.new("#{e.message} text=#{text}")
    end
  end

  class RetryExhausted < StandardError
  end

  def format(hash)
    text =
        if hash.empty?
          'Empty'
        else
          key_length = hash.keys.max_by { |k| k.to_s.length }.length
          hash.map do |key, value|
            sprintf("%#{key_length}s %s", key, value)
          end.join("\n")
        end

    "```\n" + text + "\n```"
  end
end
