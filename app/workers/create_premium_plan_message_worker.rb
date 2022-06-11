class CreatePremiumPlanMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~ERB
    ご連絡ありがとうございます。えごったーサポートです。
    (ง •̀_•́)ง

    ・有料プランの購入
    価格ページ から行えます。<%= pricing_url %>

    ・期間固定プランが購入後に有効にならない
    このプランは購入から有効になるまでに数日かかります。詳しくは商品ページをご覧ください。

    ・期間固定プランの購入時にツイッターIDの入力を忘れた
    Eメールで連絡します。Eメールの受信箱を確認してください。詳しくは商品ページをご覧ください。

    ・有料プランの解約
    設定 > 購入履歴 から行えます。<%= order_history_url %>

    ・有料プランの返金
    返金ポリシー をご覧になってください。<%= refund_policy_url %>

    ・その他の質問
    ほとんどの回答は よくある質問 に載っています。<%= support_url %>

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
    buttons = [InquiryResponseReport::QUICK_REPLY_RESOLVED, InquiryResponseReport::QUICK_REPLY_WAITING]
    User.egotter_cs.api_client.send_report(uid, build_message, buttons)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end

  private

  def build_message
    helper = UrlHelpers.new

    ERB.new(MESSAGE).result_with_hash(
        pricing_url: helper.pricing_url,
        order_history_url: helper.settings_order_history_url,
        refund_policy_url: helper.refund_policy_url,
        support_url: helper.support_url,
    )
  end

  class UrlHelpers
    include Rails.application.routes.url_helpers

    def default_url_options
      {og_tag: false, via: 'inquiry_message'}
    end
  end
end
