class CreateInquiryMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~ERB
    送り先を間違えていませんか？ 通知の送信コマンドは @ego_tter に送ってください。

    --------

    ご連絡ありがとうございます。えごったーサポートです。
    (ง •̀_•́)ง

    @ego_tter は各種の通知を送ります。@egotter_cs は個別の質問に回答します。

    「○○通知 送信」や「初期設定 開始」といったDMは、@ego_tter の方に送ってください。
    Σ(-᷅_-᷄๑)

    回答が必要な質問の場合は、そのままでしばらくお待ちください。数日中に回答いたします。
    (๑•ᴗ•๑)

    ・仲良しランキング
    自分のIDをえごったーで検索してください。その検索結果の中に仲良しランキングもあります。<%= timeline_url %>

    ・リムられ通知
    @ego_tter に「リムられ通知 送信」や「リムられ通知 使い方」というDMを送ってみてください。<%= periodic_report_url %>

    ・ブロック通知
    @ego_tter に「ブロック通知 送信」や「ブロック通知 使い方」というDMを送ってみてください。<%= block_report_url %>

    ・ミュート通知
    @ego_tter に「ミュート通知 送信」や「ミュート通知 使い方」というDMを送ってみてください。<%= mute_report_url %>

    ・ツイート削除
    ツイート削除はこちらです。<%= delete_tweets_url %>

    ・利用をやめる
    通知のDMはしばらくすると止まります。さらに詳細はこちらをご確認ください。<%= delete_account_url %>

    ・よくある質問
    よくある質問と回答はこちらです。<%= support_url %>

    #egotter
  ERB

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    30.seconds
  end

  # options:
  #   from_uid
  def perform(uid, options = {})
    user = User.find_by(uid: uid)
    event = InquiryResponseReport.build_direct_message_event(uid, build_message(user))

    unless options['from_uid'] && (sender = User.find_by(uid: options['from_uid']))
      sender = User.egotter_cs
    end
    sender.api_client.create_direct_message_event(event: event)
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end

  private

  def build_message(user)
    helper = UrlHelpers.new

    ERB.new(MESSAGE).result_with_hash(
        timeline_url: user ? helper.timeline_url(user, og_tag: false) : helper.root_url(og_tag: false),
        periodic_report_url: helper.direct_message_url(User::EGOTTER_UID, I18n.t('quick_replies.prompt_reports.label3')),
        block_report_url: helper.direct_message_url(User::EGOTTER_UID, I18n.t('quick_replies.block_reports.label4')),
        mute_report_url: helper.direct_message_url(User::EGOTTER_UID, I18n.t('quick_replies.mute_reports.label4')),
        delete_tweets_url: helper.delete_tweets_url(og_tag: false),
        delete_account_url: helper.support_url(og_tag: false, anchor: 'delete_account'),
        support_url: helper.support_url(og_tag: false),
    )
  end

  class UrlHelpers
    include Rails.application.routes.url_helpers
    include TwitterHelper

    def default_url_options
      {}
    end
  end
end
