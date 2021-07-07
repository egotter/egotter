# TODO Remove later
class CreateCsMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    「○○通知 送信」や「初期設定 開始」といったDMは、@ego_tter の方に送ってください。
    Σ(-᷅_-᷄๑)

    @ego_tter は各種の通知を送ります。@egotter_cs は個別の質問に回答します。

    回答が必要な質問の場合は、そのままでしばらくお待ちください。数日中に回答いたします。
    (๑•ᴗ•๑)

    --------

    仲良しランキングはこちらです。<%= close_friends_url %>

    ツイート削除はこちらです。<%= delete_tweets_url %>

    よくある質問の回答はこちらです。<%= support_url %>

    #egotter
  TEXT

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    30.seconds
  end

  # options:
  def perform(uid, options = {})
    User.egotter_cs.api_client.create_direct_message(uid, build_message)
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end

  private

  def build_message
    helper = Rails.application.routes.url_helpers
    ERB.new(MESSAGE).result_with_hash(
        close_friends_url: helper.close_friends_top_url(og_tag: false),
        delete_tweets_url: helper.delete_tweets_url(og_tag: false),
        support_url: helper.support_url(og_tag: false),
    )
  end
end
