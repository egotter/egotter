class CreateMemoMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~ERB
    もしかして「自分専用のメモ」をお探しですか？

    「自分だけが見ることのできるメモ」のページはこちらですよΣ(-᷅_-᷄๑) → <%= url %>

    えごったーに関するお問い合わせの場合は、@egotter_cs の方にご連絡ください。(๑•ᴗ•๑)
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
    message = ERB.new(MESSAGE).result_with_hash(
        url: MessageHelper.direct_message_url(uid)
    )
    User.egotter.api_client.create_direct_message(uid, message)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end

  module MessageHelper
    # direct_message_url
    extend TwitterHelper
  end
end
