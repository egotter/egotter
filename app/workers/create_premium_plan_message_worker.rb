class CreatePremiumPlanMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~ERB
    ご連絡ありがとうございます。えごったーサポートです。
    (ง •̀_•́)ง

    有料プランの購入は 価格ページ から行えます。
    <%= pricing_url %>

    有料プランのキャンセルは 設定 > 購入履歴 から行えます。
    <%= order_history_url %>

    よくある質問と回答はこちらです。
    <%= support_url %>

    回答が必要な質問の場合は、そのままでしばらくお待ちください。数日中に回答いたします。
    (๑•ᴗ•๑)

    #egotter
  ERB

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    30.seconds
  end

  # options:
  def perform(uid, options = {})
    # TODO Add quick-reply buttons
    User.egotter_cs.api_client.create_direct_message(uid, build_message)
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end

  private

  def build_message
    helper = UrlHelpers.new

    ERB.new(MESSAGE).result_with_hash(
        pricing_url: helper.pricing_url,
        order_history_url: helper.settings_order_history_url,
        support_url: helper.support_url,
    )
  end

  class UrlHelpers
    include Rails.application.routes.url_helpers

    def default_url_options
      {og_tag: false}
    end
  end
end
