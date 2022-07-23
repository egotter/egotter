class CreateAllReportsStoppedMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~ERB
    全ての通知（リムられ通知、検索通知、ブロック通知、ミュート通知）を停止しました。自分で再開しない限りこれらの通知が届くことはありません。

    ※ 全ての通知が止まっている間はデータの更新も止まります。

    リムられ通知の再開：
    【リムられ通知 再開】をDMで送信
    ↑ 定期的なリムられ通知を再開します。

    検索通知の再開：
    【検索通知 再開】をDMで送信
    ↑ 定期的な検索通知を再開します。

    ブロック通知の再開：
    【ブロック通知 再開】をDMで送信
    ↑ 定期的なブロック通知を再開します。

    ミュート通知の再開：
    【ミュート通知 再開】をDMで送信
    ↑ 定期的なミュート通知を再開します。

    よくある質問 <%= support_url %>
    設定ページ  <%= settings_url %>
    問い合わせアカウント @egotter_cs

    #egotter
  ERB

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in(*args)
    3.seconds
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    replies = [PeriodicReport::QUICK_REPLY_RESTART, BlockReport::QUICK_REPLY_RESTART, MuteReport::QUICK_REPLY_RESTART]
    event = DirectMessageEvent.build_with_replies(user.uid, build_message, replies)
    User.egotter.api_client.create_direct_message_event(event: event)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, user_id: user_id, options: options
    end
  end

  private

  def build_message
    helper = UrlHelpers.new

    ERB.new(MESSAGE).result_with_hash(
        support_url: helper.support_url,
        settings_url: helper.settings_url,
    )
  end

  class UrlHelpers
    include Rails.application.routes.url_helpers

    def default_url_options
      {og_tag: false}
    end
  end
end
