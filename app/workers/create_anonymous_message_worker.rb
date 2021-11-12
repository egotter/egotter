class CreateAnonymousMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    DMの送信ありがとうございます。(๑•ᴗ•๑)

    リムられ通知にはWebサイトでのログインが必要です。
    ログインお待ちしております。<%= url %>

    何かご質問でしょうか？ お返事が必要な場合は @egotter_cs までご連絡ください。
    （質問の送り先は ego_tter ではなく egotter_cs です）

    #egotter
  TEXT

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    3.seconds
  end

  # options:
  def perform(uid, options = {})
    User.egotter.api_client.create_direct_message(uid, build_message)
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end

  private

  def build_message
    url = Rails.application.routes.url_helpers.root_url(share_dialog: 1, follow_dialog: 1, purchase_dialog: 1, og_tag: false, via: 'anonymous_message')
    ERB.new(MESSAGE).result_with_hash(url: url)
  end
end
