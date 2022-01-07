class CreatePeriodicReportBlockerNotPermittedMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~ERB
    「スパム行為を行った」または「@ego_tter をブロックした」ため、全ての通知とWebサイトの利用が制限されています。

    Webサイトを今後も利用する場合は、有料プランの購入とブロックの解除が必要です。詳細はこちらのページをご覧ください。<%= url %>

    ※ 利用制限の解除のために購入された売上は、全額を特定公益増進法人（例：日本赤十字社）に寄付します。
    #egotter
  ERB

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    3.seconds
  end

  def _timeout_in
    10.seconds
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    User.egotter.api_client.create_direct_message(user.uid, build_message)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.warn "#{e.inspect} user_id=#{user_id} options=#{options}"
      Airbag.info e.backtrace.join("\n")
    end
  end

  private

  def build_message
    url = Rails.application.routes.url_helpers.error_pages_blocker_detected_url(og_tag: false, via: 'direct_message')
    ERB.new(MESSAGE).result_with_hash(url: url)
  end
end
